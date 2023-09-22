//
//  DiscoveryIntroBannerView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-19.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

public protocol DiscoveryIntroBannerViewDelegate: AnyObject {
    func discoveryIntroBannerView(_ bannerView: DiscoveryIntroBannerView, closeButtonDidPressed button: UIButton)
}

public final class DiscoveryIntroBannerView: UIView {
    var _disposeBag = Set<AnyCancellable>()
    
    public weak var delegate: DiscoveryIntroBannerViewDelegate?
    
    let label: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 16, weight: .regular))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Discovery.intro
        label.numberOfLines = 0
        return label
    }()
    
    let closeButton: HitTestExpandedButton = {
        let button = HitTestExpandedButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = Asset.Colors.Label.secondary.color
        return button
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension DiscoveryIntroBannerView {
    private func _init() {
        preservesSuperviewLayoutMargins = true
        
        setupAppearance(theme: ThemeService.shared.currentTheme)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16).priority(.required - 1),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 20).priority(.required - 1),
            closeButton.widthAnchor.constraint(equalToConstant: 20).priority(.required - 1),
        ])
        
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16).priority(.required - 1),
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            closeButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 16).priority(.required - 1),
        ])
        
        closeButton.addTarget(self, action: #selector(DiscoveryIntroBannerView.closeButtonDidPressed(_:)), for: .touchUpInside)
    }
}

extension DiscoveryIntroBannerView {
    @objc private func closeButtonDidPressed(_ sender: UIButton) {
        delegate?.discoveryIntroBannerView(self, closeButtonDidPressed: sender)
    }
}

extension DiscoveryIntroBannerView {
    
    private func setupAppearance(theme: SystemTheme) {
        backgroundColor = theme.systemBackgroundColor
    }
    
}
