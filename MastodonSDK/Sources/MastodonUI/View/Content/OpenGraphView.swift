//
//  OpenGraphView.swift
//  
//
//  Created by Kyle Bashour on 11/11/22.
//

import MastodonAsset
import MastodonCore
import OpenGraph
import UIKit

public final class OpenGraphView: UIControl {
    private let containerStackView = UIStackView()
    private let labelStackView = UIStackView()

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.cornerCurve = .continuous
        layer.cornerRadius = 10
        layer.borderColor = ThemeService.shared.currentTheme.value.separator.cgColor
        backgroundColor = ThemeService.shared.currentTheme.value.systemElevatedBackgroundColor

        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        titleLabel.text = "This is where I'd put a title... if I had one"
        titleLabel.textColor = Asset.Colors.Label.primary.color

        subtitleLabel.text = "Subtitle"
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        subtitleLabel.textColor = Asset.Colors.Label.secondary.color
        subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)

        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.15)

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(subtitleLabel)
        labelStackView.layoutMargins = .init(top: 8, left: 10, bottom: 8, right: 10)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.axis = .vertical

        containerStackView.addArrangedSubview(imageView)
        containerStackView.addArrangedSubview(labelStackView)
        containerStackView.distribution = .fill
        containerStackView.alignment = .center

        addSubview(containerStackView)

        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerStackView.heightAnchor.constraint(equalToConstant: 80),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(content: String) {
        self.subtitleLabel.text = content
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if let window = window {
            layer.borderWidth = 1 / window.screen.scale
        }
    }
}
