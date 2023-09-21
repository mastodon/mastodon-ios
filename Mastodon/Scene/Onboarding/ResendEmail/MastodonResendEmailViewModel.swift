//
//  MastodonResendEmailViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/24.
//

import Combine
import Foundation
import WebKit

final class MastodonResendEmailViewModel {
    
    // input
    let resendEmailURL: URL
    let email: String
    
    private var navigationDelegateShim: MastodonResendEmailViewModelNavigationDelegateShim?
    
    init(resendEmailURL: URL, email: String) {
        self.resendEmailURL = resendEmailURL
        self.email = email
    }
}
extension MastodonResendEmailViewModel {
    
    var navigationDelegate: WKNavigationDelegate {
        let navigationDelegateShim = MastodonResendEmailViewModelNavigationDelegateShim(viewModel: self)
        self.navigationDelegateShim = navigationDelegateShim
        return navigationDelegateShim
    }
    
}
