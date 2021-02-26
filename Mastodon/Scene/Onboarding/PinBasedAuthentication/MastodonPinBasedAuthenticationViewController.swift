//
//  MastodonPinBasedAuthenticationViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import os.log
import UIKit
import Combine
import WebKit

final class MastodonPinBasedAuthenticationViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MastodonPinBasedAuthenticationViewModel!
    
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        // cleanup cookie
        let httpCookieStore = webView.configuration.websiteDataStore.httpCookieStore
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                httpCookieStore.delete(cookie, completionHandler: nil)
            }
        }
    }
    
}
    


extension MastodonPinBasedAuthenticationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Authentication"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(MastodonPinBasedAuthenticationViewController.cancelBarButtonItemPressed(_:)))
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        let request = URLRequest(url: viewModel.authenticateURL)
        webView.navigationDelegate = viewModel.navigationDelegate
        webView.load(request)
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: authenticate via: %s", ((#file as NSString).lastPathComponent), #line, #function, viewModel.authenticateURL.debugDescription)
    }
    
}

extension MastodonPinBasedAuthenticationViewController {
    
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
