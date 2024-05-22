//
//  SpoilerOverlayView.swift
//  
//
//  Created by MainasuK on 2022-1-29.
//

import UIKit
import MastodonLocalization
import MastodonAsset
import MetaTextKit

public final class SpoilerOverlayView: UIView {
    
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()
    
    let spoilerMetaLabel = MetaLabel(style: .statusSpoilerOverlay)

    let hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.textAlignment = .center
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        return label
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension SpoilerOverlayView {
    private func _init() {
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        containerStackView.pinToParent()
        
        let topPaddingView = UIView()
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(topPaddingView)
        containerStackView.addArrangedSubview(spoilerMetaLabel)
        containerStackView.addArrangedSubview(hintLabel)
        let bottomPaddingView = UIView()
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            topPaddingView.heightAnchor.constraint(equalTo: bottomPaddingView.heightAnchor).priority(.required - 1),
        ])
        topPaddingView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
        bottomPaddingView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
        
        spoilerMetaLabel.isUserInteractionEnabled = false
        
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)
    }
}
