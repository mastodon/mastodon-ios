//
//  MastodonAuthenticationController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-4.
//

import os.log
import UIKit
import Combine
import AuthenticationServices
import MastodonCore

final class MastodonAuthenticationController {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    var context: AppContext
    let authenticateURL: URL
    var authenticationSession: ASWebAuthenticationSession?
    
    // output
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)
    let pinCodePublisher = PassthroughSubject<String, Never>()
    
    init(
        context: AppContext,
        authenticateURL: URL
    ) {
        self.context = context
        self.authenticateURL = authenticateURL
        
        authentication()
    }
    
}

extension MastodonAuthenticationController {
    private func authentication() {
        authenticationSession = ASWebAuthenticationSession(
            url: authenticateURL,
            callbackURLScheme: APIService.callbackURLScheme
        ) { [weak self] callback, error in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: callback: %s, error: %s", ((#file as NSString).lastPathComponent), #line, #function, callback?.debugDescription ?? "<nil>", error.debugDescription)
            
            if let error = error {
                if let error = error as? ASWebAuthenticationSessionError {
                    if error.errorCode == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user cancel authentication", ((#file as NSString).lastPathComponent), #line, #function)
                        self.isAuthenticating.value = false
                        return
                    }
                }
                
                self.isAuthenticating.value = false
                self.error.value = error
                return
            }
            
            guard let url = callback,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let codeQueryItem = components.queryItems?.first(where: { $0.name == "code" }),
                  let code = codeQueryItem.value else {
                return
            }
            
            self.pinCodePublisher.send(code)
        }
    }
}
