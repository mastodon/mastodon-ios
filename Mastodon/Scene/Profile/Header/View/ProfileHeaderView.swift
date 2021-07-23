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

protocol ProfileHeaderViewDelegate: AnyObject {
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, avatarImageViewDidPressed imageView: UIImageView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, bannerImageViewDidPressed imageView: UIImageView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, relationshipButtonDidPressed button: ProfileRelationshipActionButton)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, metaTextView: MetaTextView, metaDidPressed meta: Meta)

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, postDashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followingDashboardMeterViewDidPressed followingDashboardMeterView: ProfileStatusDashboardMeterView)
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followersDashboardMeterViewDidPressed followersDashboardMeterView: ProfileStatusDashboardMeterView)
}

final class ProfileHeaderView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 56, height: 56)
    static let avatarImageViewCornerRadius: CGFloat = 6
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
    
    let avatarImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        let placeholderImage = UIImage
            .placeholder(size: ProfileHeaderView.avatarImageViewSize, color: Asset.Theme.Mastodon.systemGroupedBackground.color)
            .af.imageRounded(withCornerRadius: ProfileHeaderView.avatarImageViewCornerRadius, divideRadiusByImageScale: false)
        imageView.image = placeholderImage
        return imageView
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
        metaText.textView.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold), maximumPointSize: 28)
        metaText.textView.textColor = .white
        metaText.textView.textContainer.lineFragmentPadding = 0
        metaText.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold), maximumPointSize: 28),
            .foregroundColor: UIColor.white
        ]
        return metaText
    }()
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold), maximumPointSize: 28)
        textField.textColor = .white
        textField.text = "Alice"
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.applyShadow(color: UIColor.black.withAlphaComponent(0.2), alpha: 0.5, x: 0, y: 2, blur: 2, spread: 0)
        return textField
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = Asset.Scene.Profile.Banner.usernameGray.color
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
    
    static func createFieldCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsetsReference = .readableContent
        
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(1))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        section.boundarySupplementaryItems = [header, footer]
        // note: toggle this not take effect
        // section.supplementariesFollowContentInsets = false
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    let fieldCollectionView: UICollectionView = {
        let collectionViewLayout = ProfileHeaderView.createFieldCollectionViewLayout()
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), collectionViewLayout: collectionViewLayout)
        collectionView.register(ProfileFieldCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ProfileFieldCollectionViewCell.self))
        collectionView.register(ProfileFieldAddEntryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ProfileFieldAddEntryCollectionViewCell.self))
        collectionView.register(ProfileFieldCollectionViewHeaderFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileFieldCollectionViewHeaderFooterView.headerReuseIdentifer)
        collectionView.register(ProfileFieldCollectionViewHeaderFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ProfileFieldCollectionViewHeaderFooterView.footerReuseIdentifer)
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    var fieldCollectionViewHeightLayoutConstraint: NSLayoutConstraint!
    var fieldCollectionViewHeightObservation: NSKeyValueObservation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    deinit {
        fieldCollectionViewHeightObservation = nil
    }
    
}

extension ProfileHeaderView {
    private func _init() {
        backgroundColor = ThemeService.shared.currentTheme.value.systemGroupedBackgroundColor
        fieldCollectionView.backgroundColor = ThemeService.shared.currentTheme.value.profileFieldCollectionViewBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.backgroundColor = theme.systemGroupedBackgroundColor
                self.fieldCollectionView.backgroundColor = theme.profileFieldCollectionViewBackgroundColor
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
        bannerContainerView.addSubview(avatarImageViewBackgroundView)
        NSLayoutConstraint.activate([
            avatarImageViewBackgroundView.leadingAnchor.constraint(equalTo: bannerContainerView.readableContentGuide.leadingAnchor),
            bannerContainerView.bottomAnchor.constraint(equalTo: avatarImageViewBackgroundView.bottomAnchor, constant: 20),
        ])
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageViewBackgroundView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarImageViewBackgroundView.topAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarImageViewBackgroundView.leadingAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageViewBackgroundView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageViewBackgroundView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 0.5 * ProfileHeaderView.avatarImageViewBorderWidth),
            avatarImageView.widthAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: ProfileHeaderView.avatarImageViewSize.height).priority(.required - 1),
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
            nameMetaText.textView.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
            nameMetaText.textView.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            nameMetaText.textView.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
        ])
        
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
        
        bioMetaText.textView.translatesAutoresizingMaskIntoConstraints = false
        bioContainerView.addSubview(bioMetaText.textView)
        NSLayoutConstraint.activate([
            bioMetaText.textView.topAnchor.constraint(equalTo: bioContainerView.topAnchor),
            bioMetaText.textView.leadingAnchor.constraint(equalTo: bioContainerView.readableContentGuide.leadingAnchor),
            bioMetaText.textView.trailingAnchor.constraint(equalTo: bioContainerView.readableContentGuide.trailingAnchor),
            bioMetaText.textView.bottomAnchor.constraint(equalTo: bioContainerView.bottomAnchor),
        ])
        
        fieldCollectionView.translatesAutoresizingMaskIntoConstraints = false
        metaContainerStackView.addArrangedSubview(fieldCollectionView)
        fieldCollectionViewHeightLayoutConstraint = fieldCollectionView.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            fieldCollectionViewHeightLayoutConstraint,
        ])
        fieldCollectionViewHeightObservation = fieldCollectionView.observe(\.contentSize, options: .new, changeHandler: { [weak self] tableView, _ in
            guard let self = self else { return }
            guard self.fieldCollectionView.contentSize.height != .zero else {
                self.fieldCollectionViewHeightLayoutConstraint.constant = 44
                return
            }
            self.fieldCollectionViewHeightLayoutConstraint.constant = self.fieldCollectionView.contentSize.height
        })
        
        bringSubviewToFront(bannerContainerView)
        bringSubviewToFront(nameContainerStackView)
        
        bioMetaText.textView.linkDelegate = self
        
        let avatarImageViewSingleTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        avatarImageView.addGestureRecognizer(avatarImageViewSingleTapGestureRecognizer)
        avatarImageViewSingleTapGestureRecognizer.addTarget(self, action: #selector(ProfileHeaderView.avatarImageViewDidPressed(_:)))
        
        let bannerImageViewSingleTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        bannerImageView.addGestureRecognizer(bannerImageViewSingleTapGestureRecognizer)
        bannerImageViewSingleTapGestureRecognizer.addTarget(self, action: #selector(ProfileHeaderView.bannerImageViewDidPressed(_:)))
        
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
    
    @objc private func avatarImageViewDidPressed(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileHeaderView(self, avatarImageViewDidPressed: avatarImageView)
    }
    
    @objc private func bannerImageViewDidPressed(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.profileHeaderView(self, bannerImageViewDidPressed: bannerImageView)
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
    var configurableAvatarImageView: FLAnimatedImageView? { return avatarImageView }
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
