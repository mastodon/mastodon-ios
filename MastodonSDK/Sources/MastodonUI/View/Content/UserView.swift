//
//  UserView.swift
//  
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import Combine
import MetaTextKit
import MastodonAsset
import os

public final class UserView: UIView {
    
    public enum ButtonState {
        case none, follow, unfollow, blocked
    }
    
    public var disposeBag = Set<AnyCancellable>()
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(userView: self)
        return viewModel
    }()
    
    public let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    // avatar
    public let avatarButton = AvatarButton()
    
    // author name
    public let authorNameLabel = MetaLabel(style: .statusName)
    
    // author username
    public let authorUsernameLabel = MetaLabel(style: .statusUsername)
    
    public let authorFollowersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        return label
    }()
    
    public let authorVerifiedLabel: MetaLabel = {
        let label = MetaLabel(style: .profileFieldValue)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular)),
            .foregroundColor: UIColor.secondaryLabel
        ]
        label.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold)),
            .foregroundColor: Asset.Colors.brand.color
        ]
        label.isUserInteractionEnabled = false
        return label
    }()
    
    public let authorVerifiedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let verifiedStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    private let verifiedStackCenterSpacerView: UILabel = {
        let label = UILabel()
        label.text = " · "
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let followButton: UIButton = {
        let button = FollowButton()
        button.cornerRadius = 10
        button.setTitle("Follow", for: .normal)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 96),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        return button
    }()
    
    public func setButtonState(_ state: ButtonState) {
        switch state {
        case .follow, .unfollow, .blocked:
            verifiedStackView.axis = .vertical
            verifiedStackView.alignment = .leading
            verifiedStackCenterSpacerView.isHidden = true
            followButton.isHidden = false
        case .none:
            verifiedStackView.axis = .horizontal
            verifiedStackView.alignment = .leading
            verifiedStackCenterSpacerView.isHidden = false
            followButton.isHidden = true
        }
    }
        
    public func prepareForReuse() {
        disposeBag.removeAll()
        
        // viewModel.objects.removeAll()
        viewModel.authorAvatarImageURL = nil
        
        avatarButton.avatarImageView.cancelTask()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}


extension UserView {
    
    private func _init() {
        // container
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        containerStackView.pinToParent()
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.widthAnchor.constraint(equalToConstant: 28).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: 28).priority(.required - 1),
        ])
        avatarButton.setContentHuggingPriority(.defaultLow, for: .vertical)
        avatarButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // label container
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        containerStackView.addArrangedSubview(labelStackView)
        
        // follow button
        containerStackView.addArrangedSubview(followButton)
        
        let nameStackView = UIStackView()
        nameStackView.axis = .horizontal
        
        let nameSpacer = UIView()
        nameSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        nameStackView.addArrangedSubview(authorNameLabel)
        nameStackView.addArrangedSubview(authorUsernameLabel)
        nameStackView.addArrangedSubview(nameSpacer)
        
        authorNameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        authorNameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        authorUsernameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        authorUsernameLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)
        
        labelStackView.addArrangedSubview(nameStackView)
                
        let verifiedSpacerView = UIView()
        let verifiedStackTrailingSpacerView = UIView()
        
        verifiedStackTrailingSpacerView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        let verifiedContainerStack = UIStackView()
        verifiedContainerStack.axis = .horizontal
        verifiedContainerStack.alignment = .center

        NSLayoutConstraint.activate([
            authorVerifiedImageView.widthAnchor.constraint(equalToConstant: 15),
            verifiedSpacerView.widthAnchor.constraint(equalToConstant: 2)
        ])
        
        verifiedContainerStack.addArrangedSubview(authorVerifiedImageView)
        verifiedContainerStack.addArrangedSubview(verifiedSpacerView)
        verifiedContainerStack.addArrangedSubview(authorVerifiedLabel)
        
        verifiedStackView.addArrangedSubview(authorFollowersLabel)
        verifiedStackView.addArrangedSubview(verifiedStackCenterSpacerView)
        verifiedStackView.addArrangedSubview(verifiedContainerStack)
        verifiedStackView.addArrangedSubview(verifiedStackTrailingSpacerView)
    
        labelStackView.addArrangedSubview(verifiedStackView)

        avatarButton.isUserInteractionEnabled = false
        authorNameLabel.isUserInteractionEnabled = false
        authorUsernameLabel.isUserInteractionEnabled = false

        isAccessibilityElement = true
    }
    
}

private final class FollowButton: RoundedEdgesButton {
    
    init() {
        super.init(frame: .zero)
        configureAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureAppearance() {
        setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
        setTitleColor(Asset.Colors.Label.primaryReverse.color.withAlphaComponent(0.5), for: .highlighted)
        switch traitCollection.userInterfaceStyle {
        case .dark:
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundDark.color), for: .normal)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedDark.color), for: .highlighted)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedDark.color), for: .disabled)
        default:
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundLight.color), for: .normal)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedLight.color), for: .highlighted)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedLight.color), for: .disabled)
        }
    }
}
