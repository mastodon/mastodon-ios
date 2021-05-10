//
//  AvatarConfigurableView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-4.
//

import UIKit
import AlamofireImage
import Kingfisher

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
            let placeholderImage = configuration.placeholderImage ?? UIImage.placeholder(size: Self.configurableAvatarImageSize, color: .systemFill)
            if Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 {
                return placeholderImage
                    .af.imageAspectScaled(toFill: Self.configurableAvatarImageSize)
                    .af.imageRounded(withCornerRadius: Self.configurableAvatarImageCornerRadius, divideRadiusByImageScale: true)
            } else {
                return placeholderImage.af.imageRoundedIntoCircle()
            }
        }()
        
        // cancel previous task
        configurableAvatarImageView?.af.cancelImageRequest()
        configurableAvatarImageView?.kf.cancelDownloadTask()
        configurableAvatarButton?.af.cancelImageRequest(for: .normal)
        configurableAvatarButton?.kf.cancelImageDownloadTask()
        
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

        let filter = ScaledToSizeWithRoundedCornersFilter(
            size: Self.configurableAvatarImageSize,
            radius: configuration.keepImageCorner ? 0 : Self.configurableAvatarImageCornerRadius
        )

        // set placeholder if no asset
        guard let avatarImageURL = configuration.avatarImageURL else {
            configurableAvatarImageView?.image = placeholderImage
            configurableAvatarImageView?.layer.masksToBounds = true
            configurableAvatarImageView?.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
            configurableAvatarImageView?.layer.cornerCurve = Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 ? .continuous :.circular
            
            configurableAvatarButton?.setImage(placeholderImage, for: .normal)
            configurableAvatarButton?.layer.masksToBounds = true
            configurableAvatarButton?.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
            configurableAvatarButton?.layer.cornerCurve = Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 ? .continuous :.circular
            return
        }

        if let avatarImageView = configurableAvatarImageView {
            // set avatar (GIF using Kingfisher)
            switch avatarImageURL.pathExtension {
            case "gif":
                avatarImageView.kf.setImage(
                    with: avatarImageURL,
                    placeholder: placeholderImage,
                    options: [
                        .transition(.fade(0.2))
                    ]
                )
                avatarImageView.layer.masksToBounds = true
                avatarImageView.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
                avatarImageView.layer.cornerCurve = Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 ? .continuous :.circular
                    
            default:
                avatarImageView.af.setImage(
                    withURL: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.3),
                    runImageTransitionIfCached: false,
                    completion: nil
                )
                
                if Self.configurableAvatarImageCornerRadius > 0, configuration.keepImageCorner {
                    configurableAvatarImageView?.layer.masksToBounds = true
                    configurableAvatarImageView?.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
                    configurableAvatarImageView?.layer.cornerCurve = Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 ? .continuous :.circular
                }
            }
            
            configureLayerBorder(view: avatarImageView, configuration: configuration)
        }
        
        if let avatarButton = configurableAvatarButton {
            switch avatarImageURL.pathExtension {
            case "gif":
                avatarButton.kf.setImage(
                    with: avatarImageURL,
                    for: .normal,
                    placeholder: placeholderImage,
                    options: [
                        .transition(.fade(0.2))
                    ]
                )
                avatarButton.layer.masksToBounds = true
                avatarButton.layer.cornerRadius = Self.configurableAvatarImageCornerRadius
                avatarButton.layer.cornerCurve = Self.configurableAvatarImageCornerRadius < Self.configurableAvatarImageSize.width * 0.5 ? .continuous : .circular
            default:
                avatarButton.af.setImage(
                    for: .normal,
                    url: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    completion: nil
                )
            }
            
            configureLayerBorder(view: avatarButton, configuration: configuration)
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
