//
//  MastodonPinBasedAuthenticationViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import os.log
import Foundation
import Combine
import WebKit

final class MastodonPinBasedAuthenticationViewModel {
    
    // input
    let authenticateURL: URL
    
    // output
    let pinCodePublisher = PassthroughSubject<String, Never>()
    private var navigationDelegateShim: MastodonPinBasedAuthenticationViewModelNavigationDelegateShim?
    
    init(authenticateURL: URL) {
        self.authenticateURL = authenticateURL
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonPinBasedAuthenticationViewModel {
    
    var navigationDelegate: WKNavigationDelegate {
        let navigationDelegateShim = MastodonPinBasedAuthenticationViewModelNavigationDelegateShim(viewModel: self)
        self.navigationDelegateShim = navigationDelegateShim
        return navigationDelegateShim
    }
    
}
