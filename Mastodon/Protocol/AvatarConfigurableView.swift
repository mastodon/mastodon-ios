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
                    .af.imageRounded(withCornerRadius: 4, divideRadiusByImageScale: true)
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
        
        defer {
            avatarConfigurableView(self, didFinishConfiguration: configuration)
        }
        
        // set placeholder if no asset
        guard let avatarImageURL = configuration.avatarImageURL else {
            configurableAvatarImageView?.image = placeholderImage
            configurableAvatarButton?.setImage(placeholderImage, for: .normal)
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
                let filter = ScaledToSizeWithRoundedCornersFilter(size: Self.configurableAvatarImageSize, radius: Self.configurableAvatarImageCornerRadius)
                avatarImageView.af.setImage(
                    withURL: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.3),
                    runImageTransitionIfCached: false,
                    completion: nil
                )
            }
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
                let filter = ScaledToSizeWithRoundedCornersFilter(size: Self.configurableAvatarImageSize, radius: Self.configurableAvatarImageCornerRadius)
                avatarButton.af.setImage(
                    for: .normal,
                    url: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    completion: nil
                )
            }
        }
    }
    
    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration) { }
    
}

struct AvatarConfigurableViewConfiguration {
    
    let avatarImageURL: URL?
    let placeholderImage: UIImage?
    
    init(avatarImageURL: URL?, placeholderImage: UIImage? = nil) {
        self.avatarImageURL = avatarImageURL
        self.placeholderImage = placeholderImage
    }
    
}
