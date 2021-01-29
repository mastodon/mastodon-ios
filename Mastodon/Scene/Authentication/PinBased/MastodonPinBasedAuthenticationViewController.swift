//
//  MastodonPinBasedAuthenticationViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import os.log
import Foundation
import WebKit

final class MastodonPinBasedAuthenticationViewController: NSObject {

    
    weak var viewModel: MastodonPinBasedAuthenticationViewModel?
    
    init(viewModel: MastodonPinBasedAuthenticationViewModel) {
        self.viewModel = viewModel
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
