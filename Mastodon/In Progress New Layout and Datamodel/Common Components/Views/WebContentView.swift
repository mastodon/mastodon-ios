// Copyright © 2025 Mastodon gGmbH. All rights reserved.


import SwiftUI
import WebKit

struct WebContentView: UIViewRepresentable {
    private static let contentPool = WKProcessPool()
    
    enum Style {
        case linkPreviewCard
        
        var configurationString: String {
            switch self {
            case .linkPreviewCard:
                "<meta name='viewport' content='initial-scale=1, width=device-width'><style>html, body { margin: 0; padding: 0; height: 100%; width: 100%; color-scheme: light dark; } iframe { width: 100%; height: 100%; border: 0; allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'; allowfullscreen }</style>"
                // these settings allow embedded videos to play properly
            }
        }
    }
    
    let style: Style
    let html: String
    let delegate = WebViewDelegate()

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = Self.contentPool
        config.websiteDataStore = .nonPersistent() // private/incognito mode
        config.suppressesIncrementalRendering = true
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = delegate
        webView.navigationDelegate = delegate
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(style.configurationString + html, baseURL: nil)
    }
}

class WebViewDelegate: NSObject {
    
}

extension WebViewDelegate: WKNavigationDelegate, WKUIDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        let isTopLevelNavigation: Bool
        if let frame = navigationAction.targetFrame {
            isTopLevelNavigation = frame.isMainFrame
        } else {
            isTopLevelNavigation = true
        }
        
        if isTopLevelNavigation,
           // ignore form submits and such
           navigationAction.navigationType == .linkActivated || navigationAction.navigationType == .other,
           let url = navigationAction.request.url,
           url.absoluteString != "about:blank" {
            return .cancel
        }
        return .allow
    }

}
