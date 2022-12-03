//
//  OpenGraphView.swift
//  
//
//  Created by Kyle Bashour on 11/11/22.
//

import AlamofireImage
import Combine
import MastodonAsset
import MastodonCore
import CoreDataStack
import UIKit
import WebKit

public final class StatusCardControl: UIControl {
    public var urlToOpen = PassthroughSubject<URL, Never>()

    private var disposeBag = Set<AnyCancellable>()

    private let containerStackView = UIStackView()
    private let labelStackView = UIStackView()

    private let highlightView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let linkLabel = UILabel()

    private static let cardContentPool = WKProcessPool()
    private var webView: WKWebView?

    private var layout: Layout?
    private var layoutConstraints: [NSLayoutConstraint] = []

    public override var isHighlighted: Bool {
        didSet { highlightView.isHidden = !isHighlighted }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        apply(theme: ThemeService.shared.currentTheme.value)

        ThemeService.shared.currentTheme.sink { [weak self] theme in
            self?.apply(theme: theme)
        }.store(in: &disposeBag)

        clipsToBounds = true
        layer.cornerCurve = .continuous
        layer.cornerRadius = 10

        if #available(iOS 15, *) {
            maximumContentSizeCategory = .accessibilityLarge
        }

        highlightView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        highlightView.isHidden = true

        titleLabel.numberOfLines = 2
        titleLabel.textColor = Asset.Colors.Label.primary.color
        titleLabel.font = .preferredFont(forTextStyle: .body)

        linkLabel.numberOfLines = 1
        linkLabel.textColor = Asset.Colors.Label.secondary.color
        linkLabel.font = .preferredFont(forTextStyle: .subheadline)

        imageView.tintColor = Asset.Colors.Label.secondary.color
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.setContentHuggingPriority(.zero, for: .horizontal)
        imageView.setContentHuggingPriority(.zero, for: .vertical)
        imageView.setContentCompressionResistancePriority(.zero, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.zero, for: .vertical)

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(linkLabel)
        labelStackView.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.axis = .vertical
        labelStackView.spacing = 2

        containerStackView.addArrangedSubview(imageView)
        containerStackView.addArrangedSubview(labelStackView)
        containerStackView.isUserInteractionEnabled = false
        containerStackView.distribution = .fill

        addSubview(containerStackView)
        addSubview(highlightView)

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        highlightView.translatesAutoresizingMaskIntoConstraints = false

        containerStackView.pinToParent()
        highlightView.pinToParent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(card: Card) {
        if let host = card.url?.host {
            accessibilityLabel = "\(card.title) \(host)"
        } else {
            accessibilityLabel = card.title
        }

        titleLabel.text = card.title
        linkLabel.text = card.url?.host
        imageView.contentMode = .center

        imageView.sd_setImage(
            with: card.imageURL,
            placeholderImage: icon(for: card.layout)
        ) { [weak self] image, _, _, _ in
            if image != nil {
                self?.imageView.contentMode = .scaleAspectFill
            }

            self?.containerStackView.setNeedsLayout()
            self?.containerStackView.layoutIfNeeded()
        }

        if let html = card.html, !html.isEmpty {
            let webView = setupWebView()
            webView.loadHTMLString("<meta name='viewport' content='width=device-width,user-scalable=no'><style>body { margin: 0; color-scheme: light dark; } body > :only-child { width: 100vw !important; height: 100vh !important }</style>" + html, baseURL: nil)
            addSubview(webView)
        }

        updateConstraints(for: card.layout)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if let window = window {
            layer.borderWidth = 1 / window.screen.scale
        } else {
            webView?.removeFromSuperview()
            webView = nil
        }
    }

    private func updateConstraints(for layout: Layout) {
        guard layout != self.layout else { return }
        self.layout = layout

        NSLayoutConstraint.deactivate(layoutConstraints)

        switch layout {
        case .large(let aspectRatio):
            containerStackView.alignment = .fill
            containerStackView.axis = .vertical
            layoutConstraints = [
                imageView.widthAnchor.constraint(
                    equalTo: imageView.heightAnchor,
                    multiplier: aspectRatio
                )
                // This priority is important or constraints break;
                // it still renders the card correctly.
                .priority(.defaultLow - 1),
                // set a reasonable max height for very tall images
                imageView.heightAnchor
                    .constraint(lessThanOrEqualToConstant: 400)
            ]
        case .compact:
            containerStackView.alignment = .center
            containerStackView.axis = .horizontal
            layoutConstraints = [
                imageView.heightAnchor.constraint(equalTo: heightAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 85),
                heightAnchor.constraint(equalToConstant: 85).priority(.defaultLow - 1),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 85)
            ]
        }

        if let webView {
            layoutConstraints += webView.pinTo(to: imageView)
        }

        NSLayoutConstraint.activate(layoutConstraints)
    }

    private func icon(for layout: Layout) -> UIImage? {
        switch layout {
        case .compact:
            return UIImage(systemName: "newspaper.fill")
        case .large:
            let configuration = UIImage.SymbolConfiguration(pointSize: 32)
            return UIImage(systemName: "photo", withConfiguration: configuration)
        }
    }

    private func apply(theme: Theme) {
        layer.borderColor = theme.separator.cgColor
        imageView.backgroundColor = theme.systemElevatedBackgroundColor
    }
}

extension StatusCardControl: WKNavigationDelegate, WKUIDelegate {
    fileprivate func setupWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = Self.cardContentPool
        config.websiteDataStore = .nonPersistent() // private/incognito mode
        config.suppressesIncrementalRendering = true
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView = webView
        return webView
    }

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
            urlToOpen.send(url)
            return .cancel
        }
        return .allow
    }

    public func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
        self.webView = nil
    }
}

private extension StatusCardControl {
    enum Layout: Equatable {
        case compact
        case large(aspectRatio: CGFloat)
    }
}

private extension Card {
    var layout: StatusCardControl.Layout {
        var aspectRatio = CGFloat(width) / CGFloat(height)
        if !aspectRatio.isFinite {
            aspectRatio = 1
        }
        return abs(aspectRatio - 1) < 0.05 || image == nil
        ? .compact
        : .large(aspectRatio: aspectRatio)
    }
}

private extension UILayoutPriority {
    static let zero = UILayoutPriority(rawValue: 0)
}
