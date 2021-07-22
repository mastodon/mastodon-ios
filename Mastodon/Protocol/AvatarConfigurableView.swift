//
//  AvatarConfigurableView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-4.
//

import Foundation
import UIKit
import Combine
import AlamofireImage
import FLAnimatedImage

protocol AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { get }
    static var configurableAvatarImageCornerRadius: CGFloat { get }
    var configurableAvatarImageView: FLAnimatedImageView? { get }
    func configure(with configuration: AvatarConfigurableViewConfiguration)
    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration)
}

extension AvatarConfigurableView {
    
    public func configure(with configuration: AvatarConfigurableViewConfiguration) {
        let placeholderImage: UIImage = {
            guard let placeholderImage = configuration.placeholderImage else {
                #if APP_EXTENSION
                let placeholderImage = configuration.placeholderImage ?? UIImage.placeholder(size: Self.configurableAvatarImageSize, color: .systemFill)
                if Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 {
                    return placeholderImage
                        .af.imageAspectScaled(toFill: Self.configurableAvatarImageSize)
                        .af.imageRounded(withCornerRadius: Self.configurableAvatarImageCornerRadius, divideRadiusByImageScale: false)
                } else {
                    return placeholderImage.af.imageRoundedIntoCircle()
                }
                #else
                return AppContext.shared.placeholderImageCacheService.image(
                    color: .systemFill,
                    size: Self.configurableAvatarImageSize,
                    cornerRadius: Self.configurableAvatarImageCornerRadius
                )
                #endif
            }
            return placeholderImage
        }()
        
        // accessibility
        configurableAvatarImageView?.accessibilityIgnoresInvertColors = true

        defer {
            avatarConfigurableView(self, didFinishConfiguration: configuration)
        }

        guard let configurableAvatarImageView = configurableAvatarImageView else {
            return
        }

        // set corner radius (due to GIF won't crop)
        configurableAvatarImageView.layer.masksToBounds = true
        configurableAvatarImageView.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
        configurableAvatarImageView.layer.cornerCurve = Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 ? .continuous :.circular

        // set border
        configureLayerBorder(view: configurableAvatarImageView, configuration: configuration)

        configurableAvatarImageView.setImage(
            url: configuration.avatarImageURL,
            placeholder: placeholderImage,
            scaleToSize: Self.configurableAvatarImageSize
        )
    }
    
    func configureLayerBorder(view: UIView, configuration: AvatarConfigurableViewConfiguration) {
        guard let borderWidth = configuration.borderWidth, borderWidth > 0,
              let borderColor = configuration.borderColor else {
            return
        }
        
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = borderColor.cgColor
        view.layer.borderWidth = borderWidth
    }
    
    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration) { }
    
}

struct AvatarConfigurableViewConfiguration {

    let avatarImageURL: URL?
    let placeholderImage: UIImage?
    let borderColor: UIColor?
    let borderWidth: CGFloat?
    
    let keepImageCorner: Bool
    
    init(
        avatarImageURL: URL?,
        placeholderImage: UIImage? = nil,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat? = nil,
        keepImageCorner: Bool = false       // default clip corner on image
    ) {
        self.avatarImageURL = avatarImageURL
        self.placeholderImage = placeholderImage
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.keepImageCorner = keepImageCorner
    }
    
}
