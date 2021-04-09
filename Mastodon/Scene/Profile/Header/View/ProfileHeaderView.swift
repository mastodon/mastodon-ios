//
//  ProfileBannerView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import ActiveLabel
import TwitterTextEditor

protocol ProfileHeaderViewDelegate: class {
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, relationshipButtonDidPressed button: ProfileRelationshipActionButton)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, activeLabel: ActiveLabel, entityDidPressed entity: ActiveEntity)

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, postDashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followingDashboardMeterViewDidPressed dwingDashboardMeterView: ProfileStatusDashboardMeterView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followersDashboardMeterViewDidPressed dwersDashboardMeterView: ProfileStatusDashboardMeterView)
}

final class ProfileHeaderView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 56, height: 56)
    static let avatarImageViewCornerRadius: CGFloat = 6
    static let friendshipActionButtonSize = CGSize(width: 108, height: 34)
    static let bannerImageViewPlaceholderColor = UIColor.systemGray
    
    static let bannerImageViewOverlayViewBackgroundNormalColor = UIColor.black.withAlphaComponent(0.5)
    static let bannerImageViewOverlayViewBackgroundEditingColor = UIColor.black.withAlphaComponent(0.8)
    
    weak var delegate: ProfileHeaderViewDelegate?
    
    var state: State?
    
    let bannerContainerView = UIView()
    let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = .placeholder(color: ProfileHeaderView.bannerImageViewPlaceholderColor)
        imageView.backgroundColor = ProfileHeaderView.bannerImageViewPlaceholderColor
        imageView.layer.masksToBounds = true
        // #if DEBUG
        // imageView.image = .placeholder(color: .red)
        // #endif
        return imageView
    }()
    let bannerImageViewOverlayView: UIView = {
        let overlayView = UIView()
        overlayView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundNormalColor
        return overlayView
    }()

    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        let placeholderImage = UIImage
            .placeholder(size: ProfileHeaderView.avatarImageViewSize, color: Asset.Colors.Background.systemGroupedBackground.color)
            .af.imageRounded(withCornerRadius: ProfileHeaderView.avatarImageViewCornerRadius, divideRadiusByImageScale: false)
        imageView.image = placeholderImage
        return imageView
    }()
    
    let editAvatarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = ProfileHeaderView.avatarImageViewCornerRadius
        return view
    }()
    
    let editAvatarButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton()
        button.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28)), for: .normal)
        button.tintColor = .white
        return button
    }()

    let nameTextFieldBackgroundView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 10
        return view
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        textField.textColor = .white
        textField.text = "Alice"
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.applyShadow(color: UIColor.black.withAlphaComponent(0.2), alpha: 0.5, x: 0, y: 2, blur: 2, spread: 0)
        return textField
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = Asset.Profile.Banner.usernameGray.color
        label.text = "@alice"
        label.applyShadow(color: UIColor.black.withAlphaComponent(0.2), alpha: 0.5, x: 0, y: 2, blur: 2, spread: 0)
        return label
    }()
    
    let statusDashboardView = ProfileStatusDashboardView()
    let relationshipActionButton: ProfileRelationshipActionButton = {
        let button = ProfileRelationshipActionButton()
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button
    }()
    
    let bioContainerView = UIView()
    let bioContainerStackView = UIStackView()
    let fieldContainerStackView = UIStackView()
    
    let bioActiveLabelContainer: UIView = {
        // use to set margin for active label
        // the display/edit mode bio transition animation should without flicker with that
        let view = UIView()
        // note: comment out to see how it works
        view.layoutMargins = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5) // magic from TextEditorView
        return view
    }()
    let bioActiveLabel = ActiveLabel(style: .default)
    let bioTextEditorView: TextEditorView = {
        let textEditorView = TextEditorView()
        textEditorView.scrollView.isScrollEnabled = false
        textEditorView.isScrollEnabled = false
        textEditorView.font = .preferredFont(forTextStyle: .body)
        textEditorView.backgroundColor = Asset.Profile.Banner.bioEditBackgroundGray.color
        textEditorView.layer.masksToBounds = true
        textEditorView.layer.cornerCurve = .continuous
        textEditorView.layer.cornerRadius = 10
        return textEditorView
    }()
    
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
        
        bannerImageViewOverlayView.translatesAutoresizingMaskIntoConstraints = false
        bannerImageView.addSubview(bannerImageViewOverlayView)
        NSLayoutConstraint.activate([
            bannerImageViewOverlayView.topAnchor.constraint(equalTo: bannerImageView.topAnchor),
            bannerImageViewOverlayView.leadingAnchor.constraint(equalTo: bannerImageView.leadingAnchor),
            bannerImageViewOverlayView.trailingAnchor.constraint(equalTo: bannerImageView.trailingAnchor),
            bannerImageViewOverlayView.bottomAnchor.constraint(equalTo: bannerImageView.bottomAnchor),
        ])

        // avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainerView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: bannerContainerView.readableContentGuide.leadingAnchor),
            bannerContainerView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 20),
            avatarImageView.widthAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.height).priority(.required - 1),
        ])
        
        editAvatarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(editAvatarBackgroundView)
        NSLayoutConstraint.activate([
            editAvatarBackgroundView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            editAvatarBackgroundView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            editAvatarBackgroundView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            editAvatarBackgroundView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
        ])
        
        editAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        editAvatarBackgroundView.addSubview(editAvatarButton)
        NSLayoutConstraint.activate([
            editAvatarButton.topAnchor.constraint(equalTo: editAvatarBackgroundView.topAnchor),
            editAvatarButton.leadingAnchor.constraint(equalTo: editAvatarBackgroundView.leadingAnchor),
            editAvatarButton.trailingAnchor.constraint(equalTo: editAvatarBackgroundView.trailingAnchor),
            editAvatarButton.bottomAnchor.constraint(equalTo: editAvatarBackgroundView.bottomAnchor),
        ])
        editAvatarBackgroundView.isUserInteractionEnabled = true
        avatarImageView.isUserInteractionEnabled = true

        // name container: [display name container | username]
        let nameContainerStackView = UIStackView()
        nameContainerStackView.preservesSuperviewLayoutMargins = true
        nameContainerStackView.axis = .vertical
        nameContainerStackView.spacing = 7
        nameContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameContainerStackView)
        NSLayoutConstraint.activate([
            nameContainerStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameContainerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            nameContainerStackView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
        ])
        
        let displayNameStackView = UIStackView()
        displayNameStackView.axis = .horizontal
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        displayNameStackView.addArrangedSubview(nameTextField)
        NSLayoutConstraint.activate([
            nameTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
        ])
        nameTextField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameTextFieldBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        displayNameStackView.addSubview(nameTextFieldBackgroundView)
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: nameTextFieldBackgroundView.topAnchor, constant: 5),
            nameTextField.leadingAnchor.constraint(equalTo: nameTextFieldBackgroundView.leadingAnchor, constant: 5),
            nameTextFieldBackgroundView.bottomAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 5),
            nameTextFieldBackgroundView.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor, constant: 5),
        ])
        displayNameStackView.bringSubviewToFront(nameTextField)
        displayNameStackView.addArrangedSubview(UIView())
        
        nameContainerStackView.addArrangedSubview(displayNameStackView)
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
        
        relationshipActionButton.translatesAutoresizingMaskIntoConstraints = false
        dashboardContainerView.addSubview(relationshipActionButton)
        NSLayoutConstraint.activate([
            relationshipActionButton.topAnchor.constraint(equalTo: dashboardContainerView.topAnchor),
            relationshipActionButton.leadingAnchor.constraint(greaterThanOrEqualTo: statusDashboardView.trailingAnchor, constant: 8),
            relationshipActionButton.trailingAnchor.constraint(equalTo: dashboardContainerView.readableContentGuide.trailingAnchor),
            relationshipActionButton.widthAnchor.constraint(equalToConstant: ProfileHeaderView.friendshipActionButtonSize.width).priority(.defaultHigh),
            relationshipActionButton.heightAnchor.constraint(equalToConstant: ProfileHeaderView.friendshipActionButtonSize.height).priority(.defaultHigh),
        ])
        
        bioContainerView.preservesSuperviewLayoutMargins = true
        metaContainerStackView.addArrangedSubview(bioContainerView)
        
        bioContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        bioContainerView.addSubview(bioContainerStackView)
        NSLayoutConstraint.activate([
            bioContainerStackView.topAnchor.constraint(equalTo: bioContainerView.topAnchor),
            bioContainerStackView.leadingAnchor.constraint(equalTo: bioContainerView.readableContentGuide.leadingAnchor),
            bioContainerStackView.trailingAnchor.constraint(equalTo: bioContainerView.readableContentGuide.trailingAnchor),
            bioContainerStackView.bottomAnchor.constraint(equalTo: bioContainerView.bottomAnchor),
        ])
        
        bioActiveLabel.translatesAutoresizingMaskIntoConstraints = false
        bioActiveLabelContainer.addSubview(bioActiveLabel)
        NSLayoutConstraint.activate([
            bioActiveLabel.topAnchor.constraint(equalTo: bioActiveLabelContainer.layoutMarginsGuide.topAnchor),
            bioActiveLabel.leadingAnchor.constraint(equalTo: bioActiveLabelContainer.layoutMarginsGuide.leadingAnchor),
            bioActiveLabel.trailingAnchor.constraint(equalTo: bioActiveLabelContainer.layoutMarginsGuide.trailingAnchor),
            bioActiveLabel.bottomAnchor.constraint(equalTo: bioActiveLabelContainer.layoutMarginsGuide.bottomAnchor),
        ])
        
        bioContainerStackView.axis = .vertical
        bioContainerStackView.addArrangedSubview(bioActiveLabelContainer)
        bioContainerStackView.addArrangedSubview(bioTextEditorView)
        
        fieldContainerStackView.preservesSuperviewLayoutMargins = true
        metaContainerStackView.addSubview(fieldContainerStackView)
        
        bringSubviewToFront(bannerContainerView)
        bringSubviewToFront(nameContainerStackView)
        
        bioActiveLabel.delegate = self
        
        relationshipActionButton.addTarget(self, action: #selector(ProfileHeaderView.relationshipActionButtonDidPressed(_:)), for: .touchUpInside)
        
        configure(state: .normal)
    }

}

extension ProfileHeaderView {
    enum State {
        case normal
        case editing
    }
    
    func configure(state: State) {
        guard self.state != state else { return }   // avoid redundant animation
        self.state = state
        
        let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
        
        switch state {
        case .normal:
            nameTextField.isEnabled = false
            bioActiveLabelContainer.isHidden = false
            bioTextEditorView.isHidden = true
            
            animator.addAnimations {
                self.bannerImageViewOverlayView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundNormalColor
                self.nameTextFieldBackgroundView.backgroundColor = .clear
                self.editAvatarBackgroundView.alpha = 0
            }
            animator.addCompletion { _ in
                self.editAvatarBackgroundView.isHidden = true
            }
        case .editing:
            nameTextField.isEnabled = true
            bioActiveLabelContainer.isHidden = true
            bioTextEditorView.isHidden = false
            
            editAvatarBackgroundView.isHidden = false
            editAvatarBackgroundView.alpha = 0
            bioTextEditorView.backgroundColor = .clear
            animator.addAnimations {
                self.bannerImageViewOverlayView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundEditingColor
                self.nameTextFieldBackgroundView.backgroundColor = Asset.Profile.Banner.nameEditBackgroundGray.color
                self.editAvatarBackgroundView.alpha = 1
                self.bioTextEditorView.backgroundColor = Asset.Profile.Banner.bioEditBackgroundGray.color
            }
        }
        
        animator.startAnimation()
    }
}

extension ProfileHeaderView {
    @objc private func relationshipActionButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        assert(sender === relationshipActionButton)
        delegate?.profileHeaderView(self, relationshipButtonDidPressed: relationshipActionButton)
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
