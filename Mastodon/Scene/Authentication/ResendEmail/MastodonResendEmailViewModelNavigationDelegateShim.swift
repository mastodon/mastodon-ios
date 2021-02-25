//
//  MastodonResendEmailViewModelNavigationDelegateShim.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/25.
//

import os.log
import Foundation
import WebKit

final class MastodonResendEmailViewModelNavigationDelegateShim: NSObject {
    
    weak var viewModel: MastodonResendEmailViewModel?
    
    init(viewModel: MastodonResendEmailViewModel) {
        self.viewModel = viewModel
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}


// MARK: - WKNavigationDelegate
extension MastodonResendEmailViewModelNavigationDelegateShim: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
}
