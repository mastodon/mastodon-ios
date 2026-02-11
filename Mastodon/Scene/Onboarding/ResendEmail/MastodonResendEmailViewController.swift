//
//  MastodonResendEmailViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/24.
//

import UIKit
import WebKit
import MastodonCore

final class MastodonResendEmailViewController: UIViewController {
    var viewModel: MastodonResendEmailViewModel!
    
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
    
    deinit {
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
    }
    
}

extension MastodonResendEmailViewController {
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonResendEmailViewController: OnboardingViewControllerAppearance { }
