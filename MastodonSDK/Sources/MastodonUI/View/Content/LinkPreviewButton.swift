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

public final class LinkPreviewButton: UIControl {
    private var disposeBag = Set<AnyCancellable>()

    private let containerStackView = UIStackView()
    private let labelStackView = UIStackView()

    private let highlightView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let linkLabel = UILabel()

    private lazy var compactImageConstraints = [
        imageView.heightAnchor.constraint(equalTo: heightAnchor),
        imageView.widthAnchor.constraint(equalTo: heightAnchor),
        heightAnchor.constraint(equalToConstant: 85),
    ]

    private lazy var largeImageConstraints = [
        imageView.heightAnchor.constraint(
            equalTo: imageView.widthAnchor,
            multiplier: 21 / 40
        ).priority(.defaultLow - 1),
    ]

    public override var isHighlighted: Bool {
        didSet {
            highlightView.isHidden = !isHighlighted
        }
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

        containerStackView.addArrangedSubview(imageView)
        containerStackView.addArrangedSubview(labelStackView)
        containerStackView.isUserInteractionEnabled = false

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
                self.containerStackView.setNeedsLayout()
                self.containerStackView.layoutIfNeeded()
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
        let configuration = UIImage.SymbolConfiguration(pointSize: 32)
        return UIImage(systemName: "photo", withConfiguration: configuration)
    }

    private func apply(theme: Theme) {
        layer.borderColor = theme.separator.cgColor
        imageView.backgroundColor = theme.systemElevatedBackgroundColor
    }
}

private extension UILayoutPriority {
    static let zero = UILayoutPriority(rawValue: 0)
}
