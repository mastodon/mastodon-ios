//
//  ProfileBannerView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import ActiveLabel

protocol ProfileHeaderViewDelegate: class {
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, activeLabel: ActiveLabel, entityDidPressed entity: ActiveEntity)

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, postDashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followingDashboardMeterViewDidPressed dwingDashboardMeterView: ProfileStatusDashboardMeterView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followersDashboardMeterViewDidPressed dwersDashboardMeterView: ProfileStatusDashboardMeterView)
}

final class ProfileHeaderView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 56, height: 56)
    static let avatarImageViewCornerRadius: CGFloat = 6
    static let friendshipActionButtonSize = CGSize(width: 108, height: 34)
    
    weak var delegate: ProfileHeaderViewDelegate?
    
    let bannerContainerView = UIView()
    let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = .placeholder(color: .systemGray)
        imageView.layer.masksToBounds = true
        return imageView
    }()

    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        let placeholderImage = UIImage
            .placeholder(size: ProfileHeaderView.avatarImageViewSize, color: Asset.Colors.Background.systemGroupedBackground.color)
            .af.imageRounded(withCornerRadius: ProfileHeaderView.avatarImageViewCornerRadius, divideRadiusByImageScale: false)
        imageView.image = placeholderImage
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = .white
        label.text = "Alice"
        label.applyShadow(color: UIColor.black.withAlphaComponent(0.2), alpha: 0.5, x: 0, y: 2, blur: 2, spread: 0)
        return label
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = .white
        label.text = "@alice"
        label.applyShadow(color: UIColor.black.withAlphaComponent(0.2), alpha: 0.5, x: 0, y: 2, blur: 2, spread: 0)
        return label
    }()
    
    let statusDashboardView = ProfileStatusDashboardView()
    let friendshipActionButton = ProfileFriendshipActionButton()
    
    let bioContainerView = UIView()
    let fieldContainerStackView = UIStackView()
    
    let bioActiveLabel = ActiveLabel(style: .default)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileHeaderView {
    private func _init() {
        backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        
        // banner
        bannerContainerView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainerView.preservesSuperviewLayoutMargins = true
        addSubview(bannerContainerView)
        NSLayoutConstraint.activate([
            bannerContainerView.topAnchor.constraint(equalTo: topAnchor),
            bannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: bannerContainerView.trailingAnchor),
            readableContentGuide.widthAnchor.constraint(equalTo: bannerContainerView.heightAnchor, multiplier: 3),  // set height to 1/3 of readable frame width
        ])
        
        bannerImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bannerImageView.frame = bannerContainerView.bounds
        bannerContainerView.addSubview(bannerImageView)

        // avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainerView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: bannerContainerView.readableContentGuide.leadingAnchor),
            bannerContainerView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 20),
            avatarImageView.widthAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.height).priority(.required - 1),
        ])

        // name container: [display name | username]
        let nameContainerStackView = UIStackView()
        nameContainerStackView.preservesSuperviewLayoutMargins = true
        nameContainerStackView.axis = .vertical
        nameContainerStackView.spacing = 0
        nameContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameContainerStackView)
        NSLayoutConstraint.activate([
            nameContainerStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameContainerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            nameContainerStackView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
        ])
        nameContainerStackView.addArrangedSubview(nameLabel)
        nameContainerStackView.addArrangedSubview(usernameLabel)
        
        // meta container: [dashboard container | bio container | field container]
        let metaContainerStackView = UIStackView()
        metaContainerStackView.spacing = 16
        metaContainerStackView.axis = .vertical
        metaContainerStackView.preservesSuperviewLayoutMargins = true
        metaContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metaContainerStackView)
        NSLayoutConstraint.activate([
            metaContainerStackView.topAnchor.constraint(equalTo: bannerContainerView.bottomAnchor, constant:  13),
            metaContainerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metaContainerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            metaContainerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        //  dashboard container: [dashboard | friendship action button]
        let dashboardContainerView = UIView()
        dashboardContainerView.preservesSuperviewLayoutMargins = true
        metaContainerStackView.addArrangedSubview(dashboardContainerView)
        
        statusDashboardView.translatesAutoresizingMaskIntoConstraints = false
        dashboardContainerView.addSubview(statusDashboardView)
        NSLayoutConstraint.activate([
            statusDashboardView.topAnchor.constraint(equalTo: dashboardContainerView.topAnchor),
            statusDashboardView.leadingAnchor.constraint(equalTo: dashboardContainerView.readableContentGuide.leadingAnchor),
            statusDashboardView.bottomAnchor.constraint(equalTo: dashboardContainerView.bottomAnchor),
        ])
        
        friendshipActionButton.translatesAutoresizingMaskIntoConstraints = false
        dashboardContainerView.addSubview(friendshipActionButton)
        NSLayoutConstraint.activate([
            friendshipActionButton.topAnchor.constraint(equalTo: dashboardContainerView.topAnchor),
            friendshipActionButton.leadingAnchor.constraint(greaterThanOrEqualTo: statusDashboardView.trailingAnchor, constant: 8),
            friendshipActionButton.trailingAnchor.constraint(equalTo: dashboardContainerView.readableContentGuide.trailingAnchor),
            friendshipActionButton.widthAnchor.constraint(equalToConstant: ProfileHeaderView.friendshipActionButtonSize.width).priority(.defaultHigh),
            friendshipActionButton.heightAnchor.constraint(equalToConstant: ProfileHeaderView.friendshipActionButtonSize.height).priority(.defaultHigh),
        ])
        
        bioContainerView.preservesSuperviewLayoutMargins = true
        metaContainerStackView.addArrangedSubview(bioContainerView)
        bioActiveLabel.translatesAutoresizingMaskIntoConstraints = false
        bioContainerView.addSubview(bioActiveLabel)
        NSLayoutConstraint.activate([
            bioActiveLabel.topAnchor.constraint(equalTo: bioContainerView.topAnchor),
            bioActiveLabel.leadingAnchor.constraint(equalTo: bioContainerView.readableContentGuide.leadingAnchor),
            bioActiveLabel.trailingAnchor.constraint(equalTo: bioContainerView.readableContentGuide.trailingAnchor),
            bioActiveLabel.bottomAnchor.constraint(equalTo: bioContainerView.bottomAnchor),
        ])
        
        fieldContainerStackView.preservesSuperviewLayoutMargins = true
        metaContainerStackView.addSubview(fieldContainerStackView)
        
        bringSubviewToFront(bannerContainerView)
        bringSubviewToFront(nameContainerStackView)
        
        bioActiveLabel.delegate = self
    }

}

// MARK: - ActiveLabelDelegate
extension ProfileHeaderView: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select entity: %s", ((#file as NSString).lastPathComponent), #line, #function, entity.primaryText)
        delegate?.profileHeaderView(self, activeLabel: activeLabel, entityDidPressed: entity)
    }
}

// MARK: - ProfileStatusDashboardViewDelegate
extension ProfileHeaderView: ProfileStatusDashboardViewDelegate {
    
    func profileStatusDashboardView(_ dashboardView: ProfileStatusDashboardView, postDashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView) {
        delegate?.profileHeaderView(self, profileStatusDashboardView: dashboardView, postDashboardMeterViewDidPressed: dashboardMeterView)
    }
    
    func profileStatusDashboardView(_ dashboardView: ProfileStatusDashboardView, followingDashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView) {
        delegate?.profileHeaderView(self, profileStatusDashboardView: dashboardView, followingDashboardMeterViewDidPressed: dashboardMeterView)
    }
    
    func profileStatusDashboardView(_ dashboardView: ProfileStatusDashboardView, followersDashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView) {
        delegate?.profileHeaderView(self, profileStatusDashboardView: dashboardView, followersDashboardMeterViewDidPressed: dashboardMeterView)
    }
 
}

// MARK: - AvatarConfigurableView
extension ProfileHeaderView: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { avatarImageViewSize }
    static var configurableAvatarImageCornerRadius: CGFloat { avatarImageViewCornerRadius }
    var configurableAvatarImageView: UIImageView? { return avatarImageView }
    var configurableAvatarButton: UIButton? { return nil }
}


#if DEBUG
import SwiftUI

struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let banner = ProfileHeaderView()
                banner.bannerImageView.image = UIImage(named: "lucas-ludwig")
                return banner
            }
            .previewLayout(.fixed(width: 375, height: 800))
            UIViewPreview(width: 375) {
                let banner = ProfileHeaderView()
                //banner.bannerImageView.image = UIImage(named: "peter-luo")
                return banner
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 800))
        }
    }
}
#endif
