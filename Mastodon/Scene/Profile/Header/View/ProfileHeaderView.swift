//
//  ProfileBannerView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import UIKit
import Combine
import FLAnimatedImage
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI
import MastodonSDK

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
    static let avatarImageViewBorderWidth: CGFloat = 2
    static let friendshipActionButtonSize = CGSize(width: 108, height: 34)
    static let bannerImageViewPlaceholderColor = UIColor.systemGray
    
    static let bannerImageViewOverlayViewBackgroundNormalColor = UIColor.black.withAlphaComponent(0.5)
    static let bannerImageViewOverlayViewBackgroundEditingColor = UIColor.black.withAlphaComponent(0.8)
    
    weak var delegate: ProfileHeaderViewDelegate?
    var disposeBag = Set<AnyCancellable>()
    private var _disposeBag = Set<AnyCancellable>()

    func prepareForReuse() {
        disposeBag.removeAll()
    }
    
    private(set) var viewModel: ViewModel

    let bannerImageViewSingleTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
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
    var bannerImageViewTopLayoutConstraint: NSLayoutConstraint!
    var bannerImageViewBottomLayoutConstraint: NSLayoutConstraint!
    
    let followsYouBlurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    let followsYouVibrantEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .regular), style: .label))
    let followsYouLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.text = L10n.Scene.Profile.Header.followsYou
        return label
    }()
    let followsYouMaskView = UIView()

    let avatarImageViewBackgroundView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = ProfileHeaderView.avatarImageViewCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = ProfileHeaderView.avatarImageViewBorderWidth
        view.layer.anchorPoint = CGPointMake(0.5, 1)
        return view
    }()
    
    let avatarButton: AvatarButton = {
        let button = AvatarButton()
        button.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 0)))
        button.accessibilityLabel = "Avatar image"      // FIXME: i18n
        return button
    }()

    func setupImageOverlayViews() {
        editBannerButton.tintColor = .white

        editAvatarBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        editAvatarButtonOverlayIndicatorView.tintColor = .white
    }

    static let avatarImageViewOverlayBlurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    let avatarImageViewOverlayVisualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: nil)
        visualEffectView.isUserInteractionEnabled = false
        return visualEffectView
    }()
    
    let editBannerButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton()
        button.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28)), for: .normal)
        button.tintColor = .clear
        return button
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
    
    let editAvatarButtonOverlayIndicatorView: HighlightDimmableButton = {
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
        textField.textColor = Asset.Colors.Label.primary.color
        textField.text = "Alice"
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private lazy var usernameButtonMenu: UIMenu = {
        UIMenu(children: [
            UIAction(title: L10n.Common.Controls.Actions.copy, image: UIImage(systemName: "doc.on.doc"), handler: { [weak self] _ in
                UIPasteboard.general.string = self?.usernameButton.title(for: .normal)
            })
        ])
    }()
    
    lazy var usernameButton: UIButton = {
        let button = UIButton()
        button.setTitle("@alice", for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16, weight: .regular))
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.titleLabel?.textAlignment = .natural
        button.contentHorizontalAlignment = .leading
        button.setTitleColor(Asset.Colors.Label.secondary.color, for: .normal)
        button.menu = usernameButtonMenu
        button.showsMenuAsPrimaryAction = true
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }()
    
    let statusDashboardView = ProfileStatusDashboardView()
    
    let relationshipActionButton: ProfileRelationshipActionButton = {
        let button = ProfileRelationshipActionButton()
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        return button
    }()

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
            .foregroundColor: Asset.Colors.Brand.blurple.color,
        ]
        return metaText
    }()
    
    init(account: Mastodon.Entity.Account, me: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?) {

        viewModel = ViewModel(account: account, me: me, relationship: relationship)

        super.init(frame: .zero)

        viewModel.bind(view: self)

        setColors()
        
        // banner
        bannerContainerView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainerView.preservesSuperviewLayoutMargins = true
        addSubview(bannerContainerView)
        NSLayoutConstraint.activate([
            bannerContainerView.topAnchor.constraint(equalTo: topAnchor),
            bannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: bannerContainerView.trailingAnchor),
            bannerContainerView.widthAnchor.constraint(equalTo: bannerContainerView.heightAnchor, multiplier: 3),   // aspectRatio 1 : 3
        ])
        
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainerView.addSubview(bannerImageView)
        bannerImageViewTopLayoutConstraint = bannerImageView.topAnchor.constraint(equalTo: bannerContainerView.topAnchor)
        bannerImageViewBottomLayoutConstraint = bannerContainerView.bottomAnchor.constraint(equalTo: bannerImageView.bottomAnchor)
        NSLayoutConstraint.activate([
            bannerImageViewTopLayoutConstraint,
            bannerImageView.leadingAnchor.constraint(equalTo: bannerContainerView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: bannerContainerView.trailingAnchor),
            bannerImageViewBottomLayoutConstraint,
        ])
        
        bannerImageViewOverlayVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        bannerImageView.addSubview(bannerImageViewOverlayVisualEffectView)
        bannerImageViewOverlayVisualEffectView.pinToParent()

        editBannerButton.translatesAutoresizingMaskIntoConstraints = false
        bannerContainerView.addSubview(editBannerButton)
        editBannerButton.pinTo(to: bannerImageView)
        bannerContainerView.isUserInteractionEnabled = true

        // follows you
        followsYouBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(followsYouBlurEffectView)
        NSLayoutConstraint.activate([
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: followsYouBlurEffectView.trailingAnchor),
            bannerContainerView.bottomAnchor.constraint(equalTo: followsYouBlurEffectView.bottomAnchor, constant: 16),
        ])
        followsYouBlurEffectView.layer.masksToBounds = true
        followsYouBlurEffectView.layer.cornerRadius = 8
        followsYouBlurEffectView.layer.cornerCurve = .continuous
        followsYouBlurEffectView.isHidden = true

        followsYouVibrantEffectView.translatesAutoresizingMaskIntoConstraints = false
        followsYouBlurEffectView.contentView.addSubview(followsYouVibrantEffectView)
        followsYouVibrantEffectView.pinTo(to: followsYouBlurEffectView)
        
        followsYouLabel.translatesAutoresizingMaskIntoConstraints = false
        followsYouVibrantEffectView.contentView.addSubview(followsYouLabel)
        NSLayoutConstraint.activate([
            followsYouLabel.topAnchor.constraint(equalTo: followsYouVibrantEffectView.topAnchor, constant: 4),
            followsYouLabel.leadingAnchor.constraint(equalTo: followsYouVibrantEffectView.leadingAnchor, constant: 6),
            followsYouVibrantEffectView.trailingAnchor.constraint(equalTo: followsYouLabel.trailingAnchor, constant: 6),
            followsYouVibrantEffectView.bottomAnchor.constraint(equalTo: followsYouLabel.bottomAnchor, constant: 4),
        ])
        
        followsYouMaskView.frame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        followsYouMaskView.backgroundColor = .red
        followsYouBlurEffectView.mask = followsYouMaskView
        
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
            avatarButton.topAnchor.constraint(equalTo: avatarImageViewBackgroundView.topAnchor, constant: ProfileHeaderView.avatarImageViewBorderWidth),
            avatarButton.leadingAnchor.constraint(equalTo: avatarImageViewBackgroundView.leadingAnchor, constant: ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageViewBackgroundView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageViewBackgroundView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: ProfileHeaderView.avatarImageViewBorderWidth),
            avatarButton.widthAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.width).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.height).priority(.required - 1),
        ])

        avatarImageViewOverlayVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageViewBackgroundView.addSubview(avatarImageViewOverlayVisualEffectView)
        avatarImageViewOverlayVisualEffectView.pinToParent()
    
        editAvatarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.addSubview(editAvatarBackgroundView)
        editAvatarBackgroundView.pinToParent()
        
        editAvatarButtonOverlayIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        editAvatarBackgroundView.addSubview(editAvatarButtonOverlayIndicatorView)
        editAvatarButtonOverlayIndicatorView.pinToParent()
        editAvatarBackgroundView.isUserInteractionEnabled = true
        avatarButton.isUserInteractionEnabled = true
        
        // container: V - [ dashboard container | author container | bio ]
        let container = UIStackView()
        container.axis = .vertical
        container.distribution = .fill
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
            avatarImageViewBackgroundView.bottomAnchor.constraint(equalTo: dashboardContainer.bottomAnchor, constant: ProfileHeaderView.avatarImageViewSize.height / 2),
        ])
        
        // authorContainer: H - [ nameContainer | padding | relationshipActionButton ]
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
        nameContainerStackView.addArrangedSubview(usernameButton)
        
        NSLayoutConstraint.activate([
            usernameButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
        
        authorContainer.addArrangedSubview(nameContainerStackView)
        authorContainer.addArrangedSubview(UIView())
        authorContainer.addArrangedSubview(relationshipActionButton)

        relationshipActionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            relationshipActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: ProfileHeaderView.friendshipActionButtonSize.width).priority(.required - 1),
            relationshipActionButton.heightAnchor.constraint(equalToConstant: ProfileHeaderView.friendshipActionButtonSize.height).priority(.defaultHigh),
        ])
        
        // bio
        container.addArrangedSubview(bioMetaText.textView)
    
        bringSubviewToFront(bannerContainerView)
        bringSubviewToFront(followsYouBlurEffectView)
        bringSubviewToFront(avatarImageViewBackgroundView)
        
        statusDashboardView.delegate = self
        bioMetaText.textView.delegate = self
        bioMetaText.textView.linkDelegate = self

        bannerImageView.addGestureRecognizer(bannerImageViewSingleTapGestureRecognizer)
        bannerImageViewSingleTapGestureRecognizer.addTarget(self, action: #selector(ProfileHeaderView.bannerImageViewDidPressed(_:)))
        
        avatarButton.addTarget(self, action: #selector(ProfileHeaderView.avatarButtonDidPressed(_:)), for: .touchUpInside)
        relationshipActionButton.addTarget(self, action: #selector(ProfileHeaderView.relationshipActionButtonDidPressed(_:)), for: .touchUpInside)
        
        configure(state: .normal)
        
        updateLayoutMargins()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setColors() {
        backgroundColor = .systemBackground
        avatarButton.backgroundColor = .secondarySystemBackground
        avatarImageViewBackgroundView.layer.borderColor = UIColor.systemBackground.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // workaround enter background breaking the layout issue
        switch UIApplication.shared.applicationState {
        case .active:
            updateLayoutMargins()
        default:
            break
        }
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
    @objc private func relationshipActionButtonDidPressed(_ sender: UIButton) {
        assert(sender === relationshipActionButton)
        delegate?.profileHeaderView(self, relationshipButtonDidPressed: relationshipActionButton)
    }
    
    @objc private func avatarButtonDidPressed(_ sender: UIButton) {
        assert(sender === avatarButton)
        delegate?.profileHeaderView(self, avatarButtonDidPressed: avatarButton)
    }
    
    @objc private func bannerImageViewDidPressed(_ sender: UITapGestureRecognizer) {
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
        delegate?.profileHeaderView(self, metaTextView: metaTextView, metaDidPressed: meta)
    }
}

// MARK: - ProfileStatusDashboardViewDelegate
extension ProfileHeaderView: ProfileStatusDashboardViewDelegate {
    func profileStatusDashboardView(_ dashboardView: ProfileStatusDashboardView, dashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView, meter: ProfileStatusDashboardView.Meter) {
        delegate?.profileHeaderView(self, profileStatusDashboardView: dashboardView, dashboardMeterViewDidPressed: dashboardMeterView, meter: meter)
    }
}
