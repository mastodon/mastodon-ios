//
//  WebViewController.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/30.
//

import Foundation
import Combine
import os.log
import UIKit
import WebKit
import MastodonCore

final class WebViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: WebViewModel!
    
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
    
extension WebViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(WebViewController.cancelBarButtonItemPressed(_:)))
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.pinToParent()
        
        let request = URLRequest(url: viewModel.url)
        webView.load(request)
    }
}

extension WebViewController {
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
