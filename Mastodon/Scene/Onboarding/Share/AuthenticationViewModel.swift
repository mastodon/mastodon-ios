//
//  AuthenticationViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/1.
//

import UIKit
import Combine
import MastodonSDK
import MastodonCore
import AuthenticationServices
import MastodonLocalization
import SwiftUI

@MainActor
final class AuthenticationViewModel {
    
    public let stateStream: AsyncStream<State>
    private let stateStreamContinuation: AsyncStream<State>.Continuation
    
    var disposeBag = Set<AnyCancellable>()
    var authenticationController: MastodonAuthenticationController?
    
    // input
    let input = CurrentValueSubject<String, Never>("")
    
    // output
    let domain = CurrentValueSubject<String?, Never>(nil)
    let isDomainValid = CurrentValueSubject<Bool, Never>(false)
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let isRegistering = CurrentValueSubject<Bool, Never>(false)
    let isIdle = CurrentValueSubject<Bool, Never>(true)
    let error = CurrentValueSubject<Error?, Never>(nil)
        
    init() {
        
        (stateStream, stateStreamContinuation) = AsyncStream<State>.makeStream()
        
        input
            .map { input in
                AuthenticationViewModel.parseDomain(from: input)
            }
            .assign(to: \.value, on: domain)
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            isAuthenticating.eraseToAnyPublisher(),
            isRegistering.eraseToAnyPublisher()
        )
        .map { !$0 && !$1 }
        .assign(to: \.value, on: self.isIdle)
        .store(in: &disposeBag)
        
        domain
            .map { $0 != nil }
            .assign(to: \.value, on: isDomainValid)
            .store(in: &disposeBag)
    }
    
}


extension AuthenticationViewModel {
    // Sign in to existing account
    public func logInRequested() {
        stateStreamContinuation.yield(.logInToExistingAccountRequested)
    }
    
    func logIn(on server: Mastodon.Entity.Server, withPresentationContextProvider contextProvider: ASWebAuthenticationPresentationContextProviding) async {

        stateStreamContinuation.yield(.authenticatingUser)
        
        do {
            let application = try await APIService.shared.createApplication(domain: server.domain)
            guard let authenticateInfo = AuthenticateInfo(domain: server.domain, application: application) else { throw AuthenticationError.badCredentials }
            authenticationController = MastodonAuthenticationController(
                authenticateURL: authenticateInfo.authorizeURL
            )
            guard let authenticationController else { return }
            authenticationController.authenticationSession?.presentationContextProvider = contextProvider
            authenticate(
                info: authenticateInfo,
                pinCodePublisher: authenticationController.resultStream
            )
            authenticationController.authenticationSession?.start()
        } catch let error {
            stateStreamContinuation.yield(.error(error))
        }
    }
}

extension AuthenticationViewModel {
    // Register a new account
    
    public func pickServer() {
        stateStreamContinuation.yield(.pickingServer)
    }
    
    public func joinServer(_ server: Mastodon.Entity.Server) async throws {
        
        stateStreamContinuation.yield(.joiningServer(server))
        
        let instance: RegistrationInstance
        do {
            instance = try await APIService.shared.instanceV2(domain: server.domain, authenticationBox: nil)
        } catch {
            instance = try await APIService.shared.instance(domain: server.domain, authenticationBox: nil)
            if instance.isBeyondVersion1 {
                throw APIService.APIError.explicit(.badResponse)
            }
        }
        
        guard instance.isOpenToNewRegistrations ?? true else {
            throw AuthenticationViewModel.AuthenticationError.registrationClosed
        }
        let application = try await APIService.shared.createApplication(domain: server.domain)
        
        guard let authenticateInfo = AuthenticationViewModel.AuthenticateInfo(
            domain: server.domain,
            application: application
        ) else {
            throw APIService.APIError.explicit(.badResponse)
        }
        
        let applicationToken = try await APIService.shared.applicationAccessToken(
            domain: server.domain,
            clientID: authenticateInfo.clientID,
            clientSecret: authenticateInfo.clientSecret,
            redirectURI: authenticateInfo.redirectURI
        )
        
        func doStartRegistration() {
            let mastodonRegisterViewModel = MastodonRegisterViewModel(
                domain: server.domain,
                authenticateInfo: authenticateInfo,
                instance: instance,
                applicationToken: applicationToken,
                submitValidatedUserRegistration: { [weak self] (registerInfo, hasAgreedToRules) in
                    await self?.registerNewUser(info: registerInfo, instance: server, hasAgreedToRules: hasAgreedToRules, locale: nil)
                }
            )
            stateStreamContinuation.yield(.registering(mastodonRegisterViewModel))
        }
        
        if let rules = instance.rules, !rules.isEmpty {
            // show server rules before registering
            let serverRulesViewModel = MastodonServerRulesView.ViewModel(
                disclaimer: LocalizedStringKey(L10n.Scene.ServerRules.subtitle(server.domain)),
                rules: rules,
                onAgree: { [weak self] in
                    let privacyViewModel = PolicyViewModel(domain: server.domain, authenticateInfo: authenticateInfo, instance: instance, applicationToken: applicationToken, didAccept: { doStartRegistration() })
                    self?.stateStreamContinuation.yield(.showingPrivacyPolicy(privacyViewModel))
                },
                onDisagree: { [weak self] in self?.stateStreamContinuation.yield(.showingRules(nil)) })
            stateStreamContinuation.yield(.showingRules(serverRulesViewModel))
        } else {
            doStartRegistration()
        }
    }
    
    public func registerNewUser(info: MastodonRegisterViewModel, instance: Mastodon.Entity.Server, hasAgreedToRules: Bool, locale: String?) async {
        assert(hasAgreedToRules == true)
        let query = Mastodon.API.Account.RegisterQuery(
            reason: info.reason,
            dateOfBirth: info.minAge == nil ? nil : info.dateOfBirth,
            username: info.username,
            email: info.email,
            password: info.password,
            agreement: hasAgreedToRules,
            locale: locale ?? self.locale
        )

        do {
            // register without showing server rules again
            let userToken = try await APIService.shared.accountRegister(
                domain: info.domain,
                query: query,
                authorization: info.applicationAuthorization
            )
            
            let updateCredentialQuery: Mastodon.API.Account.UpdateCredentialQuery = {
                let displayName: String? = info.name.isEmpty ? nil : info.name
                return Mastodon.API.Account.UpdateCredentialQuery(
                    displayName: displayName,
                    avatar: nil
                )
            }()
            let viewModel = MastodonConfirmEmailViewModel(email: info.email, authenticateInfo: info.authenticateInfo, userToken: userToken, updateCredentialQuery: updateCredentialQuery)
            stateStreamContinuation.yield(.confirmingEmail(viewModel))
        } catch let error {
            var errorDueToMissingLocale: Bool
            if let error = error as? Mastodon.API.Error,
                  case let .generic(errorEntity) = error.mastodonError,
               errorEntity.error == "Validation failed: Locale is not included in the list" {
                errorDueToMissingLocale = true
            } else {
                errorDueToMissingLocale = false
            }
            let fallbackLocale = instance.languages.first ?? "en"
            let alreadyTriedFallback = locale == fallbackLocale
            if errorDueToMissingLocale && !alreadyTriedFallback {
                await registerNewUser(info: info, instance: instance, hasAgreedToRules: hasAgreedToRules, locale: fallbackLocale)
            } else {
                stateStreamContinuation.yield(.error(error))
            }
        }
    }
    
    private var locale: String {
        guard let url = Bundle.main.url(forResource: "local-codes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let localCode = try? JSONDecoder().decode(MastodonLocalCode.self, from: data)
        else {
            assertionFailure()
            return "en"
        }
        let fallbackLanguageCode: String = {
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            guard localCode[code] != nil else { return "en" }
            return code
        }()
        
        // pick device preferred language
        guard let identifier = Locale.preferredLanguages.first else {
            return fallbackLanguageCode
        }
        // prepare languageCode and validate then return fallback if needs
        let local = Locale(identifier: identifier)
        guard let languageCode = local.language.languageCode?.identifier,
              localCode[languageCode] != nil
        else {
            return fallbackLanguageCode
        }
        // prepare extendCode and validate then return fallback if needs
        let extendCodes: [String] = {
            let locales = Locale.preferredLanguages.map { Locale(identifier: $0) }
            return locales.compactMap { locale in
                guard let languageCode = locale.language.languageCode?.identifier,
                      let regionIdentifier = locale.region?.identifier
                else { return nil }
                return languageCode + "-" + regionIdentifier
            }
        }()
        let _firstMatchExtendCode = extendCodes.first { code in
            localCode[code] != nil
        }
        guard let firstMatchExtendCode = _firstMatchExtendCode else {
            return languageCode
        }
        return firstMatchExtendCode
    }
}

extension AuthenticationViewModel {
    static func parseDomain(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        
        let urlString = trimmed.hasPrefix("https://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        let components = host.components(separatedBy: ".")
        guard !components.contains(where: { $0.isEmpty }) else { return nil }
        guard components.count >= 2 else { return nil }

        return host
    }
}

extension AuthenticationViewModel {
    enum State {
        case initial
        case error(Error)
        case logInToExistingAccountRequested
        case pickingServer
        case joiningServer(Mastodon.Entity.Server)
        case showingRules(MastodonServerRulesView.ViewModel?) // nil when we're returning to a previously configured state
        case registering(MastodonRegisterViewModel)
        case showingPrivacyPolicy(PolicyViewModel)
        case confirmingEmail(MastodonConfirmEmailViewModel)
        case authenticatingUser
        case authenticatedUser(MastodonAuthenticationBox)
    }
    
    enum AuthenticationError: Error, LocalizedError {
        case badCredentials
        case registrationClosed
        
        var errorDescription: String? {
            switch self {
            case .badCredentials:               return "Bad Credentials"
            case .registrationClosed:           return "Registration Closed"
            }
        }
        
        var failureReason: String? {
            switch self {
            case .badCredentials:               return "Credentials invalid."
            case .registrationClosed:           return "Server disallow registration."
            }
        }
        
        var helpAnchor: String? {
            switch self {
            case .badCredentials:               return "Please try again."
            case .registrationClosed:           return "Please try another domain."
            }
        }
    }
}

extension AuthenticationViewModel {
    
    struct AuthenticateInfo {
        let domain: String
        let clientID: String
        let clientSecret: String
        let authorizeURL: URL
        let redirectURI: String
        
        init?(
            domain: String,
            application: Mastodon.Entity.Application,
            redirectURI: String = APIService.oauthCallbackURL
        ) {
            self.domain = domain
            guard let clientID = application.clientID,
                let clientSecret = application.clientSecret else { return nil }
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.authorizeURL = {
                let query = Mastodon.API.OAuth.AuthorizeQuery(clientID: clientID, redirectURI: redirectURI)
                let url = Mastodon.API.OAuth.authorizeURL(domain: domain, query: query)
                return url
            }()
            self.redirectURI = redirectURI
        }
    }
    
    private func authenticate(info: AuthenticateInfo, pinCodePublisher: AsyncThrowingStream<String, Error>) {
        Task {
            do {
                for try await code in pinCodePublisher {
                    self.isAuthenticating.value = true
                    let token = try await APIService.shared
                        .userAccessToken(
                            domain: info.domain,
                            clientID: info.clientID,
                            clientSecret: info.clientSecret,
                            redirectURI: info.redirectURI,
                            code: code
                        )
                    let authBox = try await AuthenticationViewModel.verifyAndActivateAuthentication(
                        info: info,
                        userToken: token
                    ) // See Github issue #1432, would be better to pass along the instance configuration here rather than losing it
                    AuthenticationServiceProvider.shared.activateAuthentication(authBox)
                    self.stateStreamContinuation.yield(.authenticatedUser(authBox))
                    self.stateStreamContinuation.finish()
                }
            } catch let error {
                self.isAuthenticating.value = false
                if let error = error as? ASWebAuthenticationSessionError {
                    if error.errorCode == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return
                    }
                } else {
                    self.error.value = error
                    stateStreamContinuation.yield(.error(error))
                }
            }
        }
    }
    
    static func verifyAndActivateAuthentication(
        info: AuthenticateInfo,
        userToken: Mastodon.Entity.Token
    ) -> AnyPublisher<(Mastodon.Entity.Account, MastodonAuthenticationBox), Error> {
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: userToken.accessToken)
        return APIService.shared.verifyAndActivateUser(
            domain: info.domain,
            clientID: info.clientID,
            clientSecret: info.clientSecret,
            authorization: authorization
        )
    }
    
    static func verifyAndActivateAuthentication(
        info: AuthenticateInfo,
        userToken: Mastodon.Entity.Token
    ) async throws -> MastodonAuthenticationBox {
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: userToken.accessToken)
        
        let (_, authBox) = try await APIService.shared.verifyAndActivateUser(
            domain: info.domain,
            clientID: info.clientID,
            clientSecret: info.clientSecret,
            authorization: authorization
        )
        return authBox
    }
}
