//
//  MastodonPinBasedAuthenticationViewModelNavigationDelegateShim.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/1/29.
//

import os.log
import Foundation
import WebKit

final class MastodonPinBasedAuthenticationViewModelNavigationDelegateShim: NSObject {
    
    weak var viewModel: MastodonPinBasedAuthenticationViewModel?
    
    init(viewModel: MastodonPinBasedAuthenticationViewModel) {
        self.viewModel = viewModel
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}


// MARK: - WKNavigationDelegate
extension MastodonPinBasedAuthenticationViewModelNavigationDelegateShim: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // TODO:
    }
    
}

