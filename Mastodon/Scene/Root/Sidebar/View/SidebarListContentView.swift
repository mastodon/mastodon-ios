//
//  SidebarListContentView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-24.
//

import os.log
import UIKit
import MetaTextKit
import FLAnimatedImage

final class SidebarListContentView: UIView, UIContentView {
    
    let logger = Logger(subsystem: "SidebarListContentView", category: "UI")
    
    let imageView = UIImageView()
    let animationImageView = FLAnimatedImageView()      // for animation image
    let headlineLabel = MetaLabel(style: .sidebarHeadline(isSelected: false))
    let subheadlineLabel = MetaLabel(style: .sidebarSubheadline(isSelected: false))
    let badgeButton = BadgeButton()
    let checkmarkImageView: UIImageView = {
        let image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        let imageView = UIImageView(image: image)
        imageView.tintColor = .label
        return imageView
    }()
    
    private var currentConfiguration: ContentConfiguration!
    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? ContentConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }
        
    init(configuration: ContentConfiguration) {
        super.init(frame: .zero)
        
        _init()
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension SidebarListContentView {
    private func _init() {
        let imageViewContainer = UIView()
        imageViewContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageViewContainer)
        NSLayoutConstraint.activate([
            imageViewContainer.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            imageViewContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        imageViewContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageViewContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
                
        animationImageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewContainer.addSubview(animationImageView)
        NSLayoutConstraint.activate([
            animationImageView.centerXAnchor.constraint(equalTo: imageViewContainer.centerXAnchor),
            animationImageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor),
            animationImageView.widthAnchor.constraint(equalTo: imageViewContainer.widthAnchor, multiplier: 1.0).priority(.required - 1),
            animationImageView.heightAnchor.constraint(equalTo: imageViewContainer.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        animationImageView.setContentHuggingPriority(.defaultLow - 10, for: .vertical)
        animationImageView.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewContainer.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: imageViewContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: imageViewContainer.widthAnchor, multiplier: 1.0).priority(.required - 1),
            imageView.heightAnchor.constraint(equalTo: imageViewContainer.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        imageView.setContentHuggingPriority(.defaultLow - 10, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)
        
        let textContainer = UIStackView()
        textContainer.axis = .vertical
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textContainer)
        NSLayoutConstraint.activate([
            textContainer.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textContainer.leadingAnchor.constraint(equalTo: imageViewContainer.trailingAnchor, constant: 10),
            // textContainer.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: textContainer.bottomAnchor, constant: 12),
        ])
        
        textContainer.addArrangedSubview(headlineLabel)
        textContainer.addArrangedSubview(subheadlineLabel)
        headlineLabel.setContentHuggingPriority(.required - 9, for: .vertical)
        headlineLabel.setContentCompressionResistancePriority(.required - 9, for: .vertical)
        subheadlineLabel.setContentHuggingPriority(.required - 10, for: .vertical)
        subheadlineLabel.setContentCompressionResistancePriority(.required - 10, for: .vertical)
        
        badgeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeButton)
        NSLayoutConstraint.activate([
            badgeButton.leadingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: 4),
            badgeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 16).priority(.required - 1),
            badgeButton.widthAnchor.constraint(equalTo: badgeButton.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        badgeButton.setContentHuggingPriority(.required - 10, for: .horizontal)
        badgeButton.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        
        NSLayoutConstraint.activate([
            imageViewContainer.heightAnchor.constraint(equalTo: headlineLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            imageViewContainer.widthAnchor.constraint(equalTo: imageViewContainer.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkmarkImageView)
        NSLayoutConstraint.activate([
            checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmarkImageView.leadingAnchor.constraint(equalTo: badgeButton.trailingAnchor, constant: 16),
            checkmarkImageView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])
        checkmarkImageView.setContentHuggingPriority(.required - 9, for: .horizontal)
        checkmarkImageView.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
        
        animationImageView.isUserInteractionEnabled = false
        headlineLabel.isUserInteractionEnabled = false
        subheadlineLabel.isUserInteractionEnabled = false
        
        imageView.contentMode = .scaleAspectFit
        animationImageView.contentMode = .scaleAspectFit
        imageView.tintColor = Asset.Colors.brandBlue.color
        animationImageView.tintColor = Asset.Colors.brandBlue.color
        
        badgeButton.setBadge(number: 0)
        checkmarkImageView.isHidden = true
    }
    
    private func apply(configuration: ContentConfiguration) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration
        
        guard let item = configuration.item else { return }
        
        // configure state
        imageView.tintColor = item.isSelected ? .white : Asset.Colors.brandBlue.color
        animationImageView.tintColor = item.isSelected ? .white : Asset.Colors.brandBlue.color
        headlineLabel.setup(style: .sidebarHeadline(isSelected: item.isSelected))
        subheadlineLabel.setup(style: .sidebarSubheadline(isSelected: item.isSelected))
        
        // configure model
        imageView.isHidden = item.imageURL != nil
        animationImageView.isHidden = item.imageURL == nil
        imageView.image = item.image.withRenderingMode(.alwaysTemplate)
        animationImageView.setImage(
            url: item.imageURL,
            placeholder: animationImageView.image ?? .placeholder(color: .systemFill),  // reuse to avoid blink
            scaleToSize: nil
        )
        animationImageView.layer.masksToBounds = true
        animationImageView.layer.cornerCurve = .continuous
        animationImageView.layer.cornerRadius = 4
        
        headlineLabel.configure(content: item.headline)
        
        if let subheadline = item.subheadline {
            subheadlineLabel.configure(content: subheadline)
            subheadlineLabel.isHidden = false
        } else {
            subheadlineLabel.isHidden = true
        }
    }
}

extension SidebarListContentView {
    struct Item: Hashable {
        // state
        var isSelected: Bool = false
        
        // model
        let image: UIImage
        let imageURL: URL?
        let headline: MetaContent
        let subheadline: MetaContent?
        
        let needsOutlineDisclosure: Bool
        
        static func == (lhs: SidebarListContentView.Item, rhs: SidebarListContentView.Item) -> Bool {
            return lhs.isSelected == rhs.isSelected
                && lhs.image == rhs.image
                && lhs.imageURL == rhs.imageURL
                && lhs.headline.string == rhs.headline.string
                && lhs.subheadline?.string == rhs.subheadline?.string
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(isSelected)
            hasher.combine(image)
            imageURL.flatMap { hasher.combine($0) }
            hasher.combine(headline.string)
            subheadline.flatMap { hasher.combine($0.string) }
        }
    }
    
    struct ContentConfiguration: UIContentConfiguration, Hashable {
        let logger = Logger(subsystem: "SidebarListContentView.ContentConfiguration", category: "ContentConfiguration")
        
        var item: Item?
        
        func makeContentView() -> UIView & UIContentView {
            SidebarListContentView(configuration: self)
        }
        
        func updated(for state: UIConfigurationState) -> ContentConfiguration {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
            
            var updatedConfiguration = self
            
            if let state = state as? UICellConfigurationState {
                updatedConfiguration.item?.isSelected = state.isHighlighted || state.isSelected
            } else {
                assertionFailure()
                updatedConfiguration.item?.isSelected = false
            }
            
            return updatedConfiguration
        }
        
        static func == (
            lhs: ContentConfiguration,
            rhs: ContentConfiguration
        ) -> Bool {
            return lhs.item == rhs.item
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(item)
        }
    }
}
