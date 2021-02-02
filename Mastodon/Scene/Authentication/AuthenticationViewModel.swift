//
//  AuthenticationViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/1.
//

import os.log
import UIKit
import Combine
import MastodonSDK

final class AuthenticationViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let coordinator: SceneCoordinator
    let input = CurrentValueSubject<String, Never>("")
    let signInAction = PassthroughSubject<String, Never>()
    
    // output
    let domain = CurrentValueSubject<String?, Never>(nil)
    let isSignInButtonEnabled = CurrentValueSubject<Bool, Never>(false)
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let authenticated = PassthroughSubject<Void, Never>()
    let error = CurrentValueSubject<Error?, Never>(nil)
    
    private var mastodonPinBasedAuthenticationViewController: UIViewController?
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        
        input
            .map { input in
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !trimmed.isEmpty else { return nil }
                
                let urlString = trimmed.hasPrefix("https://") ? trimmed : "https://" + trimmed
                guard let url = URL(string: urlString),
                      let host = url.host else {
                    return nil
                }
                let components = host.components(separatedBy: ".")
                guard (components.filter { !$0.isEmpty }).count >= 2 else { return nil }
                
                return host
            }
            .assign(to: \.value, on: domain)
            .store(in: &disposeBag)
        
        domain
            .map { $0 != nil }
            .assign(to: \.value, on: isSignInButtonEnabled)
            .store(in: &disposeBag)
        
        signInAction
            .handleEvents(receiveOutput: { [weak self] _ in
                // trigger state change
                guard let self = self else { return }
                self.isAuthenticating.value = true
            })
            .flatMap { domain in
                context.apiService.createApplication(domain: domain)
                    .retry(3)
                    .tryMap { response -> AuthenticateInfo in
                        let application = response.value
                        guard let clientID = application.clientID,
                              let clientSecret = application.clientSecret else {
                            throw APIService.APIError.explicit(.badResponse)
                        }
                        let query = Mastodon.API.OAuth.AuthorizeQuery(clientID: clientID)
                        let url = Mastodon.API.OAuth.authorizeURL(domain: domain, query: query)
                        return AuthenticateInfo(
                            domain: domain,
                            clientID: clientID,
                            clientSecret: clientSecret,
                            url: url
                        )
                    }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                // trigger state update
                self.isAuthenticating.value = false
                
                switch completion {
                case .failure(let error):
                    // TODO: handle error
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign in fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    self.error.value = error
                case .finished:
                    break
                }
            } receiveValue: { [weak self] info in
                guard let self = self else { return }
                let mastodonPinBasedAuthenticationViewModel = MastodonPinBasedAuthenticationViewModel(authenticateURL: info.url)
                self.authenticate(
                    info: info,
                    pinCodePublisher: mastodonPinBasedAuthenticationViewModel.pinCodePublisher
                )
                self.mastodonPinBasedAuthenticationViewController = self.coordinator.present(
                    scene: .mastodonPinBasedAuthentication(viewModel: mastodonPinBasedAuthenticationViewModel),
                    from: nil,
                    transition: .modal(animated: true, completion: nil)
                )
            }
            .store(in: &disposeBag)
    }
    
}

extension AuthenticationViewModel {
    
    struct AuthenticateInfo {
        let domain: String
        let clientID: String
        let clientSecret: String
        let url: URL
    }
    
    func authenticate(info: AuthenticateInfo, pinCodePublisher: PassthroughSubject<String, Never>) {
        pinCodePublisher
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.isAuthenticating.value = true
                self.mastodonPinBasedAuthenticationViewController?.dismiss(animated: true, completion: nil)
                self.mastodonPinBasedAuthenticationViewController = nil
            })
            .compactMap { [weak self] code -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>? in
                guard let self = self else { return nil }
                return self.context.apiService
                    .userAccessToken(
                        domain: info.domain,
                        clientID: info.clientID,
                        clientSecret: info.clientSecret,
                        code: code
                    )
                    .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
                        let token = response.value
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign in success. Token: %s", ((#file as NSString).lastPathComponent), #line, #function, token.accessToken)
                        return AuthenticationViewModel.verifyAndSaveAuthentication(
                            context: self.context,
                            info: info,
                            token: token
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
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: swap user access token swap fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    self.isAuthenticating.value = false
                    self.error.value = error
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let account = response.value
                // TODO: 
            }
            .store(in: &self.disposeBag)
    }
    
    static func verifyAndSaveAuthentication(
        context: AppContext,
        info: AuthenticateInfo,
        token: Mastodon.Entity.Token
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: token.accessToken)
        return context.apiService.accountVerifyCredentials(
            domain: info.domain,
            authorization: authorization
        )
        // TODO: add persist logic
    }
    
}
