//
//  AuthenticationViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/1.
//

import UIKit
import CoreData
import CoreDataStack
import Combine
import MastodonSDK
import MastodonCore

final class AuthenticationViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let coordinator: SceneCoordinator
    let isAuthenticationExist: Bool
    let input = CurrentValueSubject<String, Never>("")
    
    // output
    let viewHierarchyShouldReset: Bool
    let domain = CurrentValueSubject<String?, Never>(nil)
    let isDomainValid = CurrentValueSubject<Bool, Never>(false)
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let isRegistering = CurrentValueSubject<Bool, Never>(false)
    let isIdle = CurrentValueSubject<Bool, Never>(true)
    let authenticated = PassthroughSubject<(domain: String, account: Mastodon.Entity.Account), Never>()
    let error = CurrentValueSubject<Error?, Never>(nil)
        
    init(context: AppContext, coordinator: SceneCoordinator, isAuthenticationExist: Bool) {
        self.context = context
        self.coordinator = coordinator
        self.isAuthenticationExist = isAuthenticationExist
        self.viewHierarchyShouldReset = isAuthenticationExist
        
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
    static func parseDomain(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        let https = "https://"
        let http = "http://"
        var isHTTPS = true
        let urlString = trimmed.hasPrefix(https) ? String(trimmed.dropFirst(https.count)) : {
            if trimmed.hasPrefix(http) {
                isHTTPS = false
                return String(trimmed.dropFirst(http.count))
            }
            return trimmed
        }()
        let encodedHost = urlString.split(separator: ".").map(Punycode.encode).joined(separator: ".")
        guard let url = URL(string: (isHTTPS ? https : http) + encodedHost),
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
    
    func authenticate(info: AuthenticateInfo, pinCodePublisher: PassthroughSubject<String, Never>) {
        pinCodePublisher
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.isAuthenticating.value = true
            })
            .compactMap { [weak self] code -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>? in
                guard let self = self else { return nil }
                return self.context.apiService
                    .userAccessToken(
                        domain: info.domain,
                        clientID: info.clientID,
                        clientSecret: info.clientSecret,
                        redirectURI: info.redirectURI,
                        code: code
                    )
                    .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
                        let token = response.value
                        return AuthenticationViewModel.verifyAndSaveAuthentication(
                            context: self.context,
                            info: info,
                            userToken: token
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.isAuthenticating.value = false
                    self.error.value = error
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let account = response.value
                
                self.authenticated.send((domain: info.domain, account: account))
            }
            .store(in: &self.disposeBag)
    }
    
    static func verifyAndSaveAuthentication(
        context: AppContext,
        info: AuthenticateInfo,
        userToken: Mastodon.Entity.Token
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: userToken.accessToken)

        return context.apiService.accountVerifyCredentials(
            domain: info.domain,
            authorization: authorization
        )
        .tryMap { response -> Mastodon.Response.Content<Mastodon.Entity.Account> in
            let account = response.value

            let authentication = MastodonAuthentication.createFrom(domain: info.domain,
                                                                      userID: account.id,
                                                                      username: account.username,
                                                                      appAccessToken: userToken.accessToken,  // TODO: swap app token
                                                                      userAccessToken: userToken.accessToken,
                                                                      clientID: info.clientID,
                                                                      clientSecret: info.clientSecret)

            AuthenticationServiceProvider.shared
                .authentications
                .insert(authentication, at: 0)

            FileManager.default.store(account: account, forUserID: authentication.userIdentifier())

            return response
        }
        .eraseToAnyPublisher()
    }
    
}
