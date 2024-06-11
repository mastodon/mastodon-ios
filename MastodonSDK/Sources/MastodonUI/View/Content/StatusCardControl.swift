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
import MastodonLocalization
import CoreDataStack
import UIKit
import WebKit
import MastodonSDK

public protocol StatusCardControlDelegate: AnyObject {
    func statusCardControl(_ statusCardControl: StatusCardControl, didTapURL url: URL)
    func statusCardControlMenu(_ statusCardControl: StatusCardControl) -> [LabeledAction]?
}

public final class StatusCardControl: UIControl {
    public weak var delegate: StatusCardControlDelegate?

    private var disposeBag = Set<AnyCancellable>()

    private let containerStackView = UIStackView()
    private let labelStackView = UIStackView()

    private let highlightView = UIView()
    private let dividerView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let linkLabel = UILabel()
    private lazy var showEmbedButton: UIButton = {
        var configuration = UIButton.Configuration.gray()
        configuration.background.visualEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        configuration.baseBackgroundColor = .clear
        configuration.cornerStyle = .capsule
        configuration.buttonSize = .large
        configuration.title = L10n.Common.Controls.Status.loadEmbed
        configuration.image = UIImage(systemName: "play.fill")
        configuration.imagePadding = 12
        return UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.showWebView()
        })
    }()
    private var html = ""

    private static let cardContentPool = WKProcessPool()
    private var webView: WKWebView?

    private var layout: Layout?
    private var layoutConstraints: [NSLayoutConstraint] = []
    private var dividerConstraint: NSLayoutConstraint?

    public override var isHighlighted: Bool {
        didSet {
            // override UIKit behavior of highlighting subviews when cell is highlighted
            if isHighlighted,
               let cell = sequence(first: self, next: \.superview).first(where: { $0 is UITableViewCell }) as? UITableViewCell {
                highlightView.isHidden = cell.isHighlighted
            } else {
                highlightView.isHidden = !isHighlighted
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        applyBranding()

        clipsToBounds = true
        layer.cornerCurve = .continuous
        layer.cornerRadius = 10

        maximumContentSizeCategory = .accessibilityLarge
        highlightView.backgroundColor = UIColor.label.withAlphaComponent(0.1)
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
        containerStackView.addArrangedSubview(dividerView)
        containerStackView.addArrangedSubview(labelStackView)
        containerStackView.isUserInteractionEnabled = false
        containerStackView.distribution = .fill

        addSubview(containerStackView)
        addSubview(highlightView)
        addSubview(showEmbedButton)

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        showEmbedButton.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false

        containerStackView.pinToParent()
        highlightView.pinToParent()
        NSLayoutConstraint.activate([
            showEmbedButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            showEmbedButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])

        addInteraction(UIContextMenuInteraction(delegate: self))
        isAccessibilityElement = true
        accessibilityTraits.insert(.link)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(card: Mastodon.Entity.Card) {
        let title = card.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: card.url)
        if let host = url?.host {
            accessibilityLabel = "\(title) \(host)"
        } else {
            accessibilityLabel = title
        }

        titleLabel.text = title
        linkLabel.text = url?.host
        imageView.contentMode = .center

        imageView.sd_setImage(
            with: {
                guard let image = card.image else { return nil }
                return URL(string: image)
            }(),
            placeholderImage: icon(for: card.layout)
        ) { [weak self] image, _, _, _ in
            if image != nil {
                self?.imageView.contentMode = .scaleAspectFill
            }

            self?.containerStackView.setNeedsLayout()
            self?.containerStackView.layoutIfNeeded()
        }

        if let html = card.html, !html.isEmpty {
            showEmbedButton.isHidden = false
            self.html = html
        } else {
            webView?.removeFromSuperview()
            webView = nil
            showEmbedButton.isHidden = true
            self.html = ""
        }

        updateConstraints(for: card.layout)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if let window = window {
            layer.borderWidth = window.screen.pixelSize
            dividerConstraint?.constant = window.screen.pixelSize
        }
    }

    private func updateConstraints(for layout: Layout) {
        guard layout != self.layout else { return }
        self.layout = layout

        NSLayoutConstraint.deactivate(layoutConstraints)
        dividerConstraint?.deactivate()

        let pixelSize = (window?.screen.pixelSize ?? 1)
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
                    .constraint(lessThanOrEqualToConstant: 400),
            ]
            dividerConstraint = dividerView.heightAnchor.constraint(equalToConstant: pixelSize).activate()
        case .compact:
            containerStackView.alignment = .center
            containerStackView.axis = .horizontal
            layoutConstraints = [
                imageView.heightAnchor.constraint(equalTo: heightAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 85),
                heightAnchor.constraint(equalToConstant: 85).priority(.defaultLow - 1),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 85),
                dividerView.heightAnchor.constraint(equalTo: containerStackView.heightAnchor),
            ]
            dividerConstraint = dividerView.widthAnchor.constraint(equalToConstant: pixelSize).activate()
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

    private func applyBranding() {
        layer.borderColor = SystemTheme.separator.cgColor
        dividerView.backgroundColor = SystemTheme.separator
        imageView.backgroundColor = UIColor.tertiarySystemFill
    }

    public override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            delegate?.statusCardControlMenu(self)?.map(\.accessibilityCustomAction)
        }
        set {}
    }
}

// MARK: WKWebView delegates
extension StatusCardControl: WKNavigationDelegate, WKUIDelegate {
    fileprivate func showWebView() {
        let webView = setupWebView()
        webView.loadHTMLString("<meta name='viewport' content='width=device-width,user-scalable=no'><style>body { margin: 0; color-scheme: light dark; } body > :only-child { width: 100vw !important; height: 100vh !important }</style>" + html, baseURL: nil)
        if webView.superview == nil {
            addSubview(webView)
            webView.pinTo(to: imageView)
        }
    }

    private func setupWebView() -> WKWebView {
        if let webView { return webView }

        let config = WKWebViewConfiguration()
        config.processPool = Self.cardContentPool
        config.websiteDataStore = .nonPersistent() // private/incognito mode
        config.suppressesIncrementalRendering = true
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
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
            delegate?.statusCardControl(self, didTapURL: url)
            return .cancel
        }
        return .allow
    }

    public func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
        self.webView = nil
    }
}

// MARK: UIContextMenuInteractionDelegate
extension StatusCardControl {
    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            if let elements = self.delegate?.statusCardControlMenu(self)?.map(\.menuElement) {
                return UIMenu(children: elements)
            }
            return nil
        }
    }

    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        UITargetedPreview(view: self)
    }
}

private extension StatusCardControl {
    enum Layout: Equatable {
        case compact
        case large(aspectRatio: CGFloat)
    }
}

private extension Mastodon.Entity.Card {
    var layout: StatusCardControl.Layout {
        var aspectRatio = CGFloat(width ?? 1) / CGFloat(height ?? 1)
        if !aspectRatio.isFinite {
            aspectRatio = 1
        }
        
        if (abs(aspectRatio - 1) < 0.05 || image == nil) && html == nil {
            return .compact
        } else {
            return .large(aspectRatio: aspectRatio)
        }
    }
}

private extension UILayoutPriority {
    static let zero = UILayoutPriority(rawValue: 0)
}
