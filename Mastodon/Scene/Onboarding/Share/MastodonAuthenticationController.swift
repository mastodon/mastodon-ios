//
//  MastodonAuthenticationController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-4.
//

import UIKit
import AuthenticationServices
import MastodonCore

@MainActor
final class MastodonAuthenticationController {
    // input
    let authenticateURL: URL
    var authenticationSession: ASWebAuthenticationSession?
    
    // output
    public let resultStream: AsyncThrowingStream<String, Error>
    private let resultStreamContinuation: AsyncThrowingStream<String, Error>.Continuation
    
    init(
        authenticateURL: URL
    ) {
        self.authenticateURL = authenticateURL
        
        (resultStream, resultStreamContinuation) = AsyncThrowingStream<String, Error>.makeStream()
        
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

            if let error = error {
                self.resultStreamContinuation.finish(throwing: error)
                return
            }
            
            guard let url = callback,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let codeQueryItem = components.queryItems?.first(where: { $0.name == "code" }),
                  let code = codeQueryItem.value else {
                self.resultStreamContinuation.finish()
                return
            }
            
            self.resultStreamContinuation.yield(code)
            self.resultStreamContinuation.finish()
        }
        authenticationSession?.prefersEphemeralWebBrowserSession = true
    }
}
