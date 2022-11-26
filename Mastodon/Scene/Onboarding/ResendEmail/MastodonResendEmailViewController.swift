//
//  MastodonResendEmailViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/24.
//

import Combine
import os.log
import UIKit
import WebKit
import MastodonCore

final class MastodonResendEmailViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MastodonResendEmailViewModel!
    
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        
        // cleanup cookie
        let httpCookieStore = webView.configuration.websiteDataStore.httpCookieStore
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                httpCookieStore.delete(cookie, completionHandler: nil)
            }
        }
    }
    
}
    
extension MastodonResendEmailViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOnboardingAppearance()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(MastodonResendEmailViewController.cancelBarButtonItemPressed(_:)))
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.pinToParent()
        
        let request = URLRequest(url: viewModel.resendEmailURL)
        webView.navigationDelegate = self.viewModel.navigationDelegate
        webView.load(request)
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: resendEmail via: %s", (#file as NSString).lastPathComponent, #line, #function, viewModel.resendEmailURL.debugDescription)
    }
    
}

extension MastodonResendEmailViewController {
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonResendEmailViewController: OnboardingViewControllerAppearance { }
