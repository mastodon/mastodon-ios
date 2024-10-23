//
//  WebViewController.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/30.
//

import Foundation
import Combine
import UIKit
import WebKit
import MastodonCore

class WebViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: WebViewModel
    
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
    
    required init(_ viewModel: WebViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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

class NotifyingWebViewController: WebViewController, WKNavigationDelegate {
    
    let navigationEvents: AsyncStream<URL>
    let navigationEventsContinuation: AsyncStream<URL>.Continuation
    
    @MainActor required init(_ viewModel: WebViewModel) {
        (navigationEvents, navigationEventsContinuation) = AsyncStream.makeStream()
        super.init(viewModel)
        webView.navigationDelegate = self
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    func webView(_ webView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        if let url = webView.url {
            navigationEventsContinuation.yield(url)
        }
    }
    
    func dealloc() {
        navigationEventsContinuation.finish()
    }
}
