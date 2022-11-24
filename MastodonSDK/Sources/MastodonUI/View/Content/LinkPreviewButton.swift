//
//  OpenGraphView.swift
//  
//
//  Created by Kyle Bashour on 11/11/22.
//

import AlamofireImage
import LinkPresentation
import MastodonAsset
import MastodonCore
import CoreDataStack
import UIKit

public final class LinkPreviewButton: UIControl {
    private let containerStackView = UIStackView()
    private let labelStackView = UIStackView()

    private let highlightView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let linkLabel = UILabel()

    private lazy var compactImageConstraints = [
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        imageView.heightAnchor.constraint(equalTo: heightAnchor),
        containerStackView.heightAnchor.constraint(equalToConstant: 85),
    ]

    private lazy var largeImageConstraints = [
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 21 / 40),
    ]

    public override var isHighlighted: Bool {
        didSet {
            highlightView.isHidden = !isHighlighted
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.cornerCurve = .continuous
        layer.cornerRadius = 10
        layer.borderColor = ThemeService.shared.currentTheme.value.separator.cgColor

        highlightView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        highlightView.isHidden = true

        titleLabel.numberOfLines = 2
        titleLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        titleLabel.text = "This is where I'd put a title... if I had one"
        titleLabel.textColor = Asset.Colors.Label.primary.color

        linkLabel.text = "Subtitle"
        linkLabel.numberOfLines = 1
        linkLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        linkLabel.textColor = Asset.Colors.Label.secondary.color

        imageView.tintColor = Asset.Colors.Label.secondary.color
        imageView.backgroundColor = ThemeService.shared.currentTheme.value.systemElevatedBackgroundColor
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        labelStackView.addArrangedSubview(linkLabel)
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.layoutMargins = .init(top: 8, left: 10, bottom: 8, right: 10)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.axis = .vertical

        containerStackView.addArrangedSubview(imageView)
        containerStackView.addArrangedSubview(labelStackView)

        addSubview(containerStackView)
        addSubview(highlightView)

        containerStackView.isUserInteractionEnabled = false
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        highlightView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            highlightView.topAnchor.constraint(equalTo: topAnchor),
            highlightView.bottomAnchor.constraint(equalTo: bottomAnchor),
            highlightView.leadingAnchor.constraint(equalTo: leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(card: Card) {
        let isCompact = card.width == card.height

        titleLabel.text = card.title
        linkLabel.text = card.url?.host
        imageView.contentMode = .center

        imageView.sd_setImage(
            with: card.imageURL,
            placeholderImage: isCompact ? newsIcon : photoIcon
        ) { [weak imageView] image, _, _, _ in
            if image != nil {
                imageView?.contentMode = .scaleAspectFill
            }
        }

        NSLayoutConstraint.deactivate(compactImageConstraints + largeImageConstraints)

        if isCompact {
            containerStackView.alignment = .center
            containerStackView.axis = .horizontal
            containerStackView.distribution = .fill
            NSLayoutConstraint.activate(compactImageConstraints)
        } else {
            containerStackView.alignment = .fill
            containerStackView.axis = .vertical
            containerStackView.distribution = .equalSpacing
            NSLayoutConstraint.activate(largeImageConstraints)
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if let window = window {
            layer.borderWidth = 1 / window.screen.scale
        }
    }

    private var newsIcon: UIImage? {
        UIImage(systemName: "newspaper.fill")
    }

    private var photoIcon: UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 40)
        return UIImage(systemName: "photo", withConfiguration: configuration)
    }
}
