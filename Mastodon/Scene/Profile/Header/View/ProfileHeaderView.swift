//
//  ProfileBannerView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import Combine
import FLAnimatedImage
import MetaTextKit
import MastodonAsset
import MastodonLocalization
import MastodonUI

protocol ProfileHeaderViewDelegate: AnyObject {
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, avatarButtonDidPressed button: AvatarButton)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, bannerImageViewDidPressed imageView: UIImageView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, relationshipButtonDidPressed button: ProfileRelationshipActionButton)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, metaTextView: MetaTextView, metaDidPressed meta: Meta)

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView dashboardView: ProfileStatusDashboardView, dashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView, meter: ProfileStatusDashboardView.Meter)
}

final class ProfileHeaderView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 98, height: 98)
    static let avatarImageViewCornerRadius: CGFloat = 25
    static let avatarImageViewBorderColor = UIColor.white
    static let avatarImageViewBorderWidth: CGFloat = 2
    static let friendshipActionButtonSize = CGSize(width: 108, height: 34)
    static let bannerImageViewPlaceholderColor = UIColor.systemGray
    
    static let bannerImageViewOverlayViewBackgroundNormalColor = UIColor.black.withAlphaComponent(0.5)
    static let bannerImageViewOverlayViewBackgroundEditingColor = UIColor.black.withAlphaComponent(0.8)
    
    weak var delegate: ProfileHeaderViewDelegate?
    var disposeBag = Set<AnyCancellable>()
    
    var state: State?
    
    let bannerContainerView = UIView()
    let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = .placeholder(color: ProfileHeaderView.bannerImageViewPlaceholderColor)
        imageView.backgroundColor = ProfileHeaderView.bannerImageViewPlaceholderColor
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        // accessibility
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()

    // known issue:
    // in iOS 14 blur maybe disappear when banner image moving and scaling
    static let bannerImageViewOverlayBlurEffect = UIBlurEffect(style: .systemMaterialDark)
    let bannerImageViewOverlayVisualEffectView: UIVisualEffectView = {
        let overlayView = UIVisualEffectView(effect: nil)
        overlayView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundNormalColor
        return overlayView
    }()

    let avatarImageViewBackgroundView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = ProfileHeaderView.avatarImageViewCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = ProfileHeaderView.avatarImageViewBorderColor.cgColor
        view.layer.borderWidth = ProfileHeaderView.avatarImageViewBorderWidth
        return view
    }()
    
    let avatarButton: AvatarButton = {
        let button = AvatarButton()
        button.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 0)))
        button.accessibilityLabel = "Avatar image"      // FIXME: i18n
        return button
    }()

    func setupAvatarOverlayViews() {
        editAvatarBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        editAvatarButton.tintColor = .white
    }

    static let avatarImageViewOverlayBlurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    let avatarImageViewOverlayVisualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: nil)
        visualEffectView.isUserInteractionEnabled = false
        return visualEffectView
    }()
    
    let editAvatarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear       // set value after view appeared
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = ProfileHeaderView.avatarImageViewCornerRadius
        view.alpha = 0 // set initial state invisible
        return view
    }()
    
    let editAvatarButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton()
        button.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28)), for: .normal)
        button.tintColor = .clear
        return button
    }()

    let nameTextFieldBackgroundView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 10
        return view
    }()

    let displayNameStackView = UIStackView()
    let nameMetaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.isEditable = false
        metaText.textView.isSelectable = false
        metaText.textView.isScrollEnabled = false
        metaText.textView.layer.masksToBounds = false
        metaText.textView.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        metaText.textView.textColor = .white
        metaText.textView.textContainer.lineFragmentPadding = 0
        metaText.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold)),
            .foregroundColor: Asset.Colors.Label.primary.color
        ]
        return metaText
    }()
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        textField.textColor = Asset.Colors.Label.secondary.color
        textField.text = "Alice"
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16, weight: .regular))
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "@alice"
        return label
    }()
    
    let statusDashboardView = ProfileStatusDashboardView()
    
    let relationshipActionButtonShadowContainer = ShadowBackgroundContainer()
    let relationshipActionButton: ProfileRelationshipActionButton = {
        let button = ProfileRelationshipActionButton()
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        return button
    }()
    
    let bioContainerView = UIView()
    let fieldContainerStackView = UIStackView()

    let bioMetaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.isEditable = false
        metaText.textView.isSelectable = true
        metaText.textView.isScrollEnabled = false
        //metaText.textView.textContainer.lineFragmentPadding = 0
        //metaText.textView.textContainerInset = .zero
        metaText.textView.layer.masksToBounds = false
        metaText.textView.textDragInteraction?.isEnabled = false    // disable drag for link and attachment

        metaText.textView.layer.masksToBounds = true
        metaText.textView.layer.cornerCurve = .continuous
        metaText.textView.layer.cornerRadius = 10

        metaText.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 5
            style.paragraphSpacing = 8
            return style
        }()
        metaText.textAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: Asset.Colors.Label.primary.color,
        ]
        metaText.linkAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: Asset.Colors.brandBlue.color,
        ]
        return metaText
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
        backgroundColor = ThemeService.shared.currentTheme.value.systemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.backgroundColor = theme.systemBackgroundColor
            }
            .store(in: &disposeBag)
        
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
        
        bannerImageViewOverlayVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        bannerImageView.addSubview(bannerImageViewOverlayVisualEffectView)
        NSLayoutConstraint.activate([
            bannerImageViewOverlayVisualEffectView.topAnchor.constraint(equalTo: bannerImageView.topAnchor),
            bannerImageViewOverlayVisualEffectView.leadingAnchor.constraint(equalTo: bannerImageView.leadingAnchor),
            bannerImageViewOverlayVisualEffectView.trailingAnchor.constraint(equalTo: bannerImageView.trailingAnchor),
            bannerImageViewOverlayVisualEffectView.bottomAnchor.constraint(equalTo: bannerImageView.bottomAnchor),
        ])

        // avatar
        avatarImageViewBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarImageViewBackgroundView)
        NSLayoutConstraint.activate([
            avatarImageViewBackgroundView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            // align to dashboardContainer bottom
        ])
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarImageViewBackgroundView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: avatarImageViewBackgroundView.topAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarButton.leadingAnchor.constraint(equalTo: avatarImageViewBackgroundView.leadingAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageViewBackgroundView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageViewBackgroundView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarButton.widthAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.width).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.height).priority(.required - 1),
        ])

        avatarImageViewOverlayVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageViewBackgroundView.addSubview(avatarImageViewOverlayVisualEffectView)
        NSLayoutConstraint.activate([
            avatarImageViewOverlayVisualEffectView.topAnchor.constraint(equalTo: avatarImageViewBackgroundView.topAnchor),
            avatarImageViewOverlayVisualEffectView.leadingAnchor.constraint(equalTo: avatarImageViewBackgroundView.leadingAnchor),
            avatarImageViewOverlayVisualEffectView.trailingAnchor.constraint(equalTo: avatarImageViewBackgroundView.trailingAnchor),
            avatarImageViewOverlayVisualEffectView.bottomAnchor.constraint(equalTo: avatarImageViewBackgroundView.bottomAnchor),
        ])
    
        editAvatarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.addSubview(editAvatarBackgroundView)
        NSLayoutConstraint.activate([
            editAvatarBackgroundView.topAnchor.constraint(equalTo: avatarButton.topAnchor),
            editAvatarBackgroundView.leadingAnchor.constraint(equalTo: avatarButton.leadingAnchor),
            editAvatarBackgroundView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
            editAvatarBackgroundView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),
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
        avatarButton.isUserInteractionEnabled = true
        
        // container: V - [ dashboard container | author container | bio ]
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins.top = 12
        
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: bannerContainerView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // dashboardContainer: H - [ padding | statusDashboardView ]
        let dashboardContainer = UIStackView()
        dashboardContainer.axis = .horizontal
        container.addArrangedSubview(dashboardContainer)
        
        let dashboardPaddingView = UIView()
        dashboardContainer.addArrangedSubview(dashboardPaddingView)
        dashboardContainer.addArrangedSubview(statusDashboardView)
        
        NSLayoutConstraint.activate([
            avatarImageViewBackgroundView.bottomAnchor.constraint(equalTo: dashboardContainer.bottomAnchor),
        ])
        
        // authorContainer: H - [ nameContainer | padding | relationshipActionButtonShadowContainer ]
        let authorContainer = UIStackView()
        authorContainer.axis = .horizontal
        authorContainer.alignment = .top
        authorContainer.spacing = 10
        container.addArrangedSubview(authorContainer)
        
        // name container: V - [ display name container | username ]
        let nameContainerStackView = UIStackView()
        nameContainerStackView.preservesSuperviewLayoutMargins = true
        nameContainerStackView.axis = .vertical
        nameContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        
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

        // overlay meta text for display name
        nameMetaText.textView.translatesAutoresizingMaskIntoConstraints = false
        displayNameStackView.addSubview(nameMetaText.textView)
        NSLayoutConstraint.activate([
            nameMetaText.textView.topAnchor.constraint(equalTo: nameTextFieldBackgroundView.topAnchor),
            nameMetaText.textView.leadingAnchor.constraint(equalTo: nameTextFieldBackgroundView.leadingAnchor, constant: 5),
            nameTextFieldBackgroundView.trailingAnchor.constraint(equalTo: nameMetaText.textView.trailingAnchor, constant: 5),
            nameMetaText.textView.bottomAnchor.constraint(equalTo: nameTextFieldBackgroundView.bottomAnchor),
        ])
        
        nameContainerStackView.addArrangedSubview(displayNameStackView)
        nameContainerStackView.addArrangedSubview(usernameLabel)
        
        authorContainer.addArrangedSubview(nameContainerStackView)
        authorContainer.addArrangedSubview(UIView())
        authorContainer.addArrangedSubview(relationshipActionButtonShadowContainer)
        
        relationshipActionButton.translatesAutoresizingMaskIntoConstraints = false
        relationshipActionButtonShadowContainer.addSubview(relationshipActionButton)
        NSLayoutConstraint.activate([
            relationshipActionButton.topAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.topAnchor),
            relationshipActionButton.leadingAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.leadingAnchor),
            relationshipActionButton.trailingAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.trailingAnchor),
            relationshipActionButton.bottomAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.bottomAnchor),
            relationshipActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: ProfileHeaderView.friendshipActionButtonSize.width).priority(.required - 1),
            relationshipActionButton.heightAnchor.constraint(equalToConstant: ProfileHeaderView.friendshipActionButtonSize.height).priority(.defaultHigh),
        ])
        
        // bio
        container.addArrangedSubview(bioMetaText.textView)
    
        bringSubviewToFront(bannerContainerView)
        bringSubviewToFront(avatarImageViewBackgroundView)
        
        statusDashboardView.delegate = self
        bioMetaText.textView.delegate = self
        bioMetaText.textView.linkDelegate = self
        
        let bannerImageViewSingleTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        bannerImageView.addGestureRecognizer(bannerImageViewSingleTapGestureRecognizer)
        bannerImageViewSingleTapGestureRecognizer.addTarget(self, action: #selector(ProfileHeaderView.bannerImageViewDidPressed(_:)))
        
        avatarButton.addTarget(self, action: #selector(ProfileHeaderView.avatarButtonDidPressed(_:)), for: .touchUpInside)
        relationshipActionButton.addTarget(self, action: #selector(ProfileHeaderView.relationshipActionButtonDidPressed(_:)), for: .touchUpInside)
        
        configure(state: .normal)
        
        updateLayoutMargins()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateLayoutMargins()
    }

}

extension ProfileHeaderView {
    private func updateLayoutMargins() {
        let margin: CGFloat = {
            switch traitCollection.userInterfaceIdiom {
            case .phone:
                return ProfileViewController.containerViewMarginForCompactHorizontalSizeClass
            default:
                return traitCollection.horizontalSizeClass == .regular ?
                    ProfileViewController.containerViewMarginForRegularHorizontalSizeClass :
                    ProfileViewController.containerViewMarginForCompactHorizontalSizeClass
            }
        }()
        
        layoutMargins.left = margin
        layoutMargins.right = margin
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
            nameMetaText.textView.alpha = 1
            nameTextField.alpha = 0
            nameTextField.isEnabled = false
            bioMetaText.textView.backgroundColor = .clear

            animator.addAnimations {
                self.bannerImageViewOverlayVisualEffectView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundNormalColor
                self.nameTextFieldBackgroundView.backgroundColor = .clear
                self.editAvatarBackgroundView.alpha = 0
            }
            animator.addCompletion { _ in
                self.editAvatarBackgroundView.isHidden = true
            }
        case .editing:
            nameMetaText.textView.alpha = 0
            nameTextField.isEnabled = true
            nameTextField.alpha = 1
            
            editAvatarBackgroundView.isHidden = false
            editAvatarBackgroundView.alpha = 0
            bioMetaText.textView.backgroundColor = .clear
            animator.addAnimations {
                self.bannerImageViewOverlayVisualEffectView.backgroundColor = ProfileHeaderView.bannerImageViewOverlayViewBackgroundEditingColor
                self.nameTextFieldBackgroundView.backgroundColor = Asset.Scene.Profile.Banner.nameEditBackgroundGray.color
                self.editAvatarBackgroundView.alpha = 1
                self.bioMetaText.textView.backgroundColor = Asset.Scene.Profile.Banner.bioEditBackgroundGray.color
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
    
    @objc private func avatarButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        assert(sender === avatarButton)
        delegate?.profileHeaderView(self, avatarButtonDidPressed: avatarButton)
    }
    
    @objc private func bannerImageViewDidPressed(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileHeaderView(self, bannerImageViewDidPressed: bannerImageView)
    }
}

// MARK: - UITextViewDelegate
extension ProfileHeaderView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch textView {
        case bioMetaText.textView:
            return false
        default:
            assertionFailure()
            return true
        }
    }
}

// MARK: - MetaTextViewDelegate
extension ProfileHeaderView: MetaTextViewDelegate {
    func metaTextView(_ metaTextView: MetaTextView, didSelectMeta meta: Meta) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select entity", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileHeaderView(self, metaTextView: metaTextView, metaDidPressed: meta)
    }
}

// MARK: - ProfileStatusDashboardViewDelegate
extension ProfileHeaderView: ProfileStatusDashboardViewDelegate {
    func profileStatusDashboardView(_ dashboardView: ProfileStatusDashboardView, dashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView, meter: ProfileStatusDashboardView.Meter) {
        delegate?.profileHeaderView(self, profileStatusDashboardView: dashboardView, dashboardMeterViewDidPressed: dashboardMeterView, meter: meter)
    }
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
