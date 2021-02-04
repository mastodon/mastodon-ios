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
    static var configurableAvatarImageViewSize: CGSize { get }
    static var configurableAvatarImageViewBadgeAppearanceStyle: AvatarConfigurableViewConfiguration.BadgeAppearanceStyle { get }
    var configurableAvatarImageView: UIImageView? { get }
    var configurableAvatarButton: UIButton? { get }
    var configurableVerifiedBadgeImageView: UIImageView? { get }
    func configure(withConfigurationInput input: AvatarConfigurableViewConfiguration.Input)
    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration)
}

extension AvatarConfigurableView {
    
    static var configurableAvatarImageViewBadgeAppearanceStyle: AvatarConfigurableViewConfiguration.BadgeAppearanceStyle { return .mini }
    
    public func configure(withConfigurationInput input: AvatarConfigurableViewConfiguration.Input) {
        // TODO: set badge
        configurableVerifiedBadgeImageView?.isHidden = true
        
        let cornerRadius = Self.configurableAvatarImageViewSize.width * 0.5
        // let scale = (configurableAvatarImageView ?? configurableAvatarButton)?.window?.screen.scale ?? UIScreen.main.scale

        let placeholderImage: UIImage = {
            let placeholderImage = input.placeholderImage ?? UIImage.placeholder(size: Self.configurableAvatarImageViewSize, color: .systemFill)
            return placeholderImage.af.imageRoundedIntoCircle()
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
            let configuration = AvatarConfigurableViewConfiguration(input: input)
            avatarConfigurableView(self, didFinishConfiguration: configuration)
        }
        
        // set placeholder if no asset
        guard let avatarImageURL = input.avatarImageURL else {
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
                avatarImageView.layer.cornerRadius = cornerRadius
                avatarImageView.layer.cornerCurve = .circular
            default:
                let filter = ScaledToSizeCircleFilter(size: Self.configurableAvatarImageViewSize)
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
                avatarButton.layer.cornerRadius = cornerRadius
                avatarButton.layer.cornerCurve = .circular
            default:
                let filter = ScaledToSizeCircleFilter(size: Self.configurableAvatarImageViewSize)
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
    
    enum BadgeAppearanceStyle {
        case mini
        case normal
    }
    
    struct Input {
        let avatarImageURL: URL?
        let placeholderImage: UIImage?
        let blocked: Bool
        let verified: Bool
        
        init(avatarImageURL: URL?, placeholderImage: UIImage? = nil, blocked: Bool = false, verified: Bool = false) {
            self.avatarImageURL = avatarImageURL
            self.placeholderImage = placeholderImage
            self.blocked = blocked
            self.verified = verified
        }
    }
    
    let input: Input
    
}
