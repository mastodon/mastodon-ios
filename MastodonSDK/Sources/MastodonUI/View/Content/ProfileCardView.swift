//
//  ProfileCardView.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import MastodonAsset

public protocol ProfileCardViewDelegate: AnyObject {
    func profileCardView(_ profileCardView: ProfileCardView, relationshipButtonDidPressed button: ProfileRelationshipActionButton)
}

public final class ProfileCardView: UIView {
    
    static let avatarSize = CGSize(width: 56, height: 56)
    static let friendshipActionButtonSize = CGSize(width: 108, height: 34)
    static let contentMargin: CGFloat = 16

    weak var delegate: ProfileCardViewDelegate?
    private var _disposeBag = Set<AnyCancellable>()
    var disposeBag = Set<AnyCancellable>()
    
    let container = UIStackView()
    
    let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 3
        imageView.layer.cornerCurve = .continuous
        return imageView
    }()
    
    // avatar
    public let avatarButtonBackgroundView = UIView()
    public let avatarButton = AvatarButton()
    
    // author name
    public let authorNameLabel = MetaLabel(style: .profileCardName)
    
    // author username
    public let authorUsernameLabel = MetaLabel(style: .profileCardUsername)
    
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
    
    let statusDashboardView = ProfileStatusDashboardView()
    
    let relationshipActionButtonShadowContainer = ShadowBackgroundContainer()
    let relationshipActionButton: ProfileRelationshipActionButton = {
        let button = ProfileRelationshipActionButton()
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        return button
    }()
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    public func prepareForReuse() {
        disposeBag.removeAll()
        bannerImageView.af.cancelImageRequest()
        bannerImageView.image = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileCardView {
    private func _init() {
        avatarButton.isUserInteractionEnabled = false
        authorNameLabel.isUserInteractionEnabled = false
        authorUsernameLabel.isUserInteractionEnabled = false
        bioMetaText.textView.isUserInteractionEnabled = false
        statusDashboardView.isUserInteractionEnabled = false        
        
        // container: V - [ bannerContainer | authorContainer | bioMetaText | infoContainer ]
        container.axis = .vertical
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // bannerContainer
        let bannerContainer = UIView()
        bannerContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(bannerContainer)
        container.setCustomSpacing(6, after: bannerContainer)
        
        // bannerImageView
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainer.addSubview(bannerImageView)
        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: bannerContainer.topAnchor, constant: 4),
            bannerImageView.leadingAnchor.constraint(equalTo: bannerContainer.leadingAnchor, constant: 4),
            bannerContainer.trailingAnchor.constraint(equalTo: bannerImageView.trailingAnchor, constant: 4),
            bannerImageView.bottomAnchor.constraint(equalTo: bannerContainer.bottomAnchor),
            bannerImageView.widthAnchor.constraint(equalTo: bannerImageView.heightAnchor, multiplier: 335.0/128.0).priority(.required - 1),
        ])
        
        // authorContainer: H - [ avatarPlaceholder | authorInfoContainer ]
        let authorContainer = UIStackView()
        authorContainer.axis = .horizontal
        authorContainer.spacing = 16
        let authorContainerAdaptiveMarginContainerView = AdaptiveMarginContainerView()
        authorContainerAdaptiveMarginContainerView.contentView = authorContainer
        authorContainerAdaptiveMarginContainerView.margin = ProfileCardView.contentMargin
        container.addArrangedSubview(authorContainerAdaptiveMarginContainerView)
        
        // avatarPlaceholder
        let avatarPlaceholder = UIView()
        avatarPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        authorContainer.addArrangedSubview(avatarPlaceholder)
        NSLayoutConstraint.activate([
            avatarPlaceholder.widthAnchor.constraint(equalToConstant: ProfileCardView.avatarSize.width).priority(.required - 1),
            avatarPlaceholder.heightAnchor.constraint(equalToConstant: ProfileCardView.avatarSize.height - 14).priority(.required - 1),
        ])
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        authorContainer.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.leadingAnchor.constraint(equalTo: avatarPlaceholder.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarPlaceholder.trailingAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarPlaceholder.bottomAnchor),
            avatarButton.heightAnchor.constraint(equalToConstant: ProfileCardView.avatarSize.height).priority(.required - 1),
        ])
        
        avatarButtonBackgroundView.layer.masksToBounds = true
        avatarButtonBackgroundView.layer.cornerCurve = .continuous
        avatarButtonBackgroundView.layer.cornerRadius = 12
        avatarButtonBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        authorContainer.insertSubview(avatarButtonBackgroundView, belowSubview: avatarButton)
        NSLayoutConstraint.activate([
            avatarButtonBackgroundView.centerXAnchor.constraint(equalTo: avatarButton.centerXAnchor),
            avatarButtonBackgroundView.centerYAnchor.constraint(equalTo: avatarButton.centerYAnchor),
            avatarButtonBackgroundView.widthAnchor.constraint(equalToConstant: ProfileCardView.avatarSize.width + 4).priority(.required - 1),
            avatarButtonBackgroundView.heightAnchor.constraint(equalToConstant: ProfileCardView.avatarSize.height + 4).priority(.required - 1),
        ])
        
        // authorInfoContainer: V - [ authorNameLabel | authorUsernameLabel ]
        let authorInfoContainer = UIStackView()
        authorInfoContainer.axis = .vertical
        authorInfoContainer.spacing = 2
        authorContainer.addArrangedSubview(authorInfoContainer)
    
        authorInfoContainer.addArrangedSubview(authorNameLabel)
        authorInfoContainer.addArrangedSubview(authorUsernameLabel)
        
        // bioMetaText
        let bioMetaTextAdaptiveMarginContainerView = AdaptiveMarginContainerView()
        bioMetaTextAdaptiveMarginContainerView.contentView = bioMetaText.textView
        bioMetaTextAdaptiveMarginContainerView.margin = ProfileCardView.contentMargin
        container.addArrangedSubview(bioMetaTextAdaptiveMarginContainerView)
        container.setCustomSpacing(16, after: bioMetaTextAdaptiveMarginContainerView)
        
        // infoContainer: H - [ statusDashboardView | (spacer) | relationshipActionButton ]
        let infoContainer = UIStackView()
        infoContainer.axis = .horizontal
        let infoContainerAdaptiveMarginContainerView = AdaptiveMarginContainerView()
        infoContainerAdaptiveMarginContainerView.contentView = infoContainer
        infoContainerAdaptiveMarginContainerView.margin = ProfileCardView.contentMargin
        container.addArrangedSubview(infoContainerAdaptiveMarginContainerView)
        infoContainer.addArrangedSubview(statusDashboardView)
        infoContainer.addArrangedSubview(UIView())
        let relationshipActionButtonShadowContainer = ShadowBackgroundContainer()
        infoContainer.addArrangedSubview(relationshipActionButtonShadowContainer)
        
        relationshipActionButton.translatesAutoresizingMaskIntoConstraints = false
        relationshipActionButtonShadowContainer.addSubview(relationshipActionButton)
        NSLayoutConstraint.activate([
            relationshipActionButton.topAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.topAnchor),
            relationshipActionButton.leadingAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.leadingAnchor),
            relationshipActionButton.trailingAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.trailingAnchor),
            relationshipActionButton.bottomAnchor.constraint(equalTo: relationshipActionButtonShadowContainer.bottomAnchor),
            relationshipActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: ProfileCardView.friendshipActionButtonSize.width).priority(.required - 1),
            relationshipActionButton.heightAnchor.constraint(equalToConstant: ProfileCardView.friendshipActionButtonSize.height).priority(.defaultHigh),
        ])
        
        let bottomPadding = UIView()
        bottomPadding.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(bottomPadding)
        NSLayoutConstraint.activate([
            bottomPadding.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        relationshipActionButton.addTarget(self, action: #selector(ProfileCardView.relationshipActionButtonDidPressed(_:)), for: .touchUpInside)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        viewModel.userInterfaceStyle = traitCollection.userInterfaceStyle
    }

}

extension ProfileCardView {
    @objc private func relationshipActionButtonDidPressed(_ sender: UIButton) {
        os_log(.debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        assert(sender === relationshipActionButton)
        delegate?.profileCardView(self, relationshipButtonDidPressed: relationshipActionButton)
    }
}
