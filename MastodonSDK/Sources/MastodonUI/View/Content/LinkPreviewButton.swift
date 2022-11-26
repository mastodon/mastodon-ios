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

    private let labelContainer = UIView()
    private let highlightView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let linkLabel = UILabel()

    private lazy var compactImageConstraints = [
        labelContainer.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        labelContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
        labelContainer.leadingAnchor.constraint(equalTo: imageView.trailingAnchor),
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        imageView.heightAnchor.constraint(equalTo: heightAnchor),
        heightAnchor.constraint(equalToConstant: 85),
    ]

    private lazy var largeImageConstraints = [
        labelContainer.topAnchor.constraint(equalTo: imageView.bottomAnchor),
        labelContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        labelContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 21 / 40),
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        imageView.widthAnchor.constraint(equalTo: widthAnchor),
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

        labelContainer.addSubview(titleLabel)
        labelContainer.addSubview(linkLabel)
        labelContainer.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)

        addSubview(imageView)
        addSubview(labelContainer)
        addSubview(highlightView)

        subviews.forEach { $0.isUserInteractionEnabled = false }

        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        linkLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        highlightView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: labelContainer.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: labelContainer.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: labelContainer.layoutMarginsGuide.trailingAnchor),

            linkLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            linkLabel.bottomAnchor.constraint(equalTo: labelContainer.layoutMarginsGuide.bottomAnchor),
            linkLabel.leadingAnchor.constraint(equalTo: labelContainer.layoutMarginsGuide.leadingAnchor),
            linkLabel.trailingAnchor.constraint(equalTo: labelContainer.layoutMarginsGuide.trailingAnchor),

            labelContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),

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
            NSLayoutConstraint.activate(compactImageConstraints)
        } else {
            NSLayoutConstraint.activate(largeImageConstraints)
        }

        setNeedsLayout()
        layoutIfNeeded()
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
