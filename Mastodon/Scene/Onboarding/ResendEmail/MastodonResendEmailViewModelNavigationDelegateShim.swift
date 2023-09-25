//
//  MastodonResendEmailViewModelNavigationDelegateShim.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/25.
//

import Foundation
import WebKit

final class MastodonResendEmailViewModelNavigationDelegateShim: NSObject {
    
    weak var viewModel: MastodonResendEmailViewModel?
    
    init(viewModel: MastodonResendEmailViewModel) {
        self.viewModel = viewModel
    }
    
}


// MARK: - WKNavigationDelegate
extension MastodonResendEmailViewModelNavigationDelegateShim: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let email = self.viewModel?.email else {
            return
        }
        let scriptString = "document.getElementById('user_email').value = '\(email)';"
        webView.evaluateJavaScript(scriptString)
    }
    
}
