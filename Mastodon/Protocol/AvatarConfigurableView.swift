//
//  AvatarConfigurableView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-4.
//

import UIKit
import AlamofireImage
import FLAnimatedImage
import Nuke

protocol AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { get }
    static var configurableAvatarImageCornerRadius: CGFloat { get }
    var configurableAvatarImageView: UIImageView? { get }
    var configurableAvatarButton: UIButton? { get }
    func configure(with configuration: AvatarConfigurableViewConfiguration)
    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration)
}

extension AvatarConfigurableView {
    
    public func configure(with configuration: AvatarConfigurableViewConfiguration) {
        let placeholderImage: UIImage = {
            guard let placeholderImage = configuration.placeholderImage else {
                return AppContext.shared.placeholderImageCacheService.image(
                    color: .systemFill,
                    size: Self.configurableAvatarImageSize,
                    cornerRadius: Self.configurableAvatarImageCornerRadius
                )
            }
            return placeholderImage
        }()

        // reset layer attributes
        configurableAvatarImageView?.layer.masksToBounds = false
        configurableAvatarImageView?.layer.cornerRadius = 0
        configurableAvatarImageView?.layer.cornerCurve = .circular
        
        configurableAvatarButton?.layer.masksToBounds = false
        configurableAvatarButton?.layer.cornerRadius = 0
        configurableAvatarButton?.layer.cornerCurve = .circular
        
        // accessibility
        configurableAvatarImageView?.accessibilityIgnoresInvertColors = true
        configurableAvatarButton?.accessibilityIgnoresInvertColors = true
        
        defer {
            avatarConfigurableView(self, didFinishConfiguration: configuration)
        }

        guard let imageDisplayingView: ImageDisplayingView = configurableAvatarImageView ?? configurableAvatarButton?.imageView else {
            return
        }

        // set corner radius (due to GIF won't crop)
        imageDisplayingView.layer.masksToBounds = true
        imageDisplayingView.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
        imageDisplayingView.layer.cornerCurve = Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 ? .continuous :.circular

        // set border
        configureLayerBorder(view: imageDisplayingView, configuration: configuration)


        // set image
        let url = configuration.avatarImageURL
        let processors: [ImageProcessing] = [
            ImageProcessors.Resize(
                size: Self.configurableAvatarImageSize,
                unit: .points,
                contentMode: .aspectFill,
                crop: false
            ),
            ImageProcessors.RoundedCorners(
                radius: Self.configurableAvatarImageCornerRadius
            )
        ]

        let request = ImageRequest(url: url, processors: processors)
        let options = ImageLoadingOptions(
            placeholder: placeholderImage,
            transition: .fadeIn(duration: 0.2)
        )

        Nuke.loadImage(
            with: request,
            options: options,
            into: imageDisplayingView
        ) { result in
            switch result {
            case .failure:
                break
            case .success:
                break
            }
        }
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
