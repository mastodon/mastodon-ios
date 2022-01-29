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

final class SpoilerOverlayView: UIView {
    
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        // stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "eye", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 34, weight: .light)))
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.textAlignment = .center
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Common.Controls.Status.contentWarning
        return label
    }()
    
    let spoilerMetaLabel = MetaLabel(style: .statusSpoiler)
    
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
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        
        let topPaddingView = UIView()
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(topPaddingView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 52.0).priority(.required - 1),
            iconImageView.heightAnchor.constraint(equalToConstant: 32.0).priority(.required - 1),
        ])
        iconImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(spoilerMetaLabel)
        let bottomPaddingView = UIView()
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            topPaddingView.heightAnchor.constraint(equalTo: bottomPaddingView.heightAnchor).priority(.required - 1),
        ])
        topPaddingView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
        bottomPaddingView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
    }
    
    public func setComponentHidden(_ isHidden: Bool) {
        containerStackView.arrangedSubviews.forEach { $0.isHidden = isHidden }
    }
}
