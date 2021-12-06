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
    let avatarButton: CircleAvatarButton = {
        let button = CircleAvatarButton()
        button.borderWidth = 2
        button.borderColor = UIColor.label
        return button
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
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: 40).priority(.required - 1),
            imageView.heightAnchor.constraint(equalToConstant: 40).priority(.required - 1),
        ])

        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            avatarButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            avatarButton.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0).priority(.required - 2),
            avatarButton.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1.0).priority(.required - 2),
        ])
        avatarButton.setContentHuggingPriority(.defaultLow - 10, for: .vertical)
        avatarButton.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)

        imageView.contentMode = .scaleAspectFit
        avatarButton.contentMode = .scaleAspectFit
        
        imageView.isUserInteractionEnabled = false
        avatarButton.isUserInteractionEnabled = false
    }
    
    private func apply(configuration: ContentConfiguration) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration
        
        guard let item = configuration.item else { return }
        
        // configure state
        let tintColor = item.isHighlighted ? ThemeService.tintColor.withAlphaComponent(0.5) : ThemeService.tintColor
        imageView.tintColor = tintColor
        avatarButton.tintColor = tintColor
        
        // configure model
        imageView.isHidden = item.imageURL != nil
        avatarButton.isHidden = item.imageURL == nil
        imageView.image = item.image.withRenderingMode(.alwaysTemplate)
        avatarButton.avatarImageView.setImage(
            url: item.imageURL,
            placeholder: avatarButton.avatarImageView.image ?? .placeholder(color: .systemFill),  // reuse to avoid blink
            scaleToSize: nil
        )
    }
}

extension SidebarListContentView {
    struct Item: Hashable {
        // state
        var isSelected: Bool = false
        var isHighlighted: Bool = false
        
        // model
        let title: String
        let image: UIImage
        let imageURL: URL?
                
        static func == (lhs: SidebarListContentView.Item, rhs: SidebarListContentView.Item) -> Bool {
            return lhs.isSelected == rhs.isSelected
                && lhs.isHighlighted == rhs.isHighlighted
                && lhs.title == rhs.title
                && lhs.image == rhs.image
                && lhs.imageURL == rhs.imageURL
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(isSelected)
            hasher.combine(isHighlighted)
            hasher.combine(title)
            hasher.combine(image)
            imageURL.flatMap { hasher.combine($0) }
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
                updatedConfiguration.item?.isHighlighted = state.isHighlighted
            } else {
                assertionFailure()
                updatedConfiguration.item?.isSelected = false
                updatedConfiguration.item?.isHighlighted = false
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
