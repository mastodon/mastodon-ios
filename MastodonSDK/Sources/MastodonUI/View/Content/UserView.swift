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
import MastodonLocalization
import os
import CoreDataStack
import MastodonSDK

public protocol UserViewDelegate: AnyObject {
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for user: Mastodon.Entity.Account, me: Mastodon.Entity.Account?)
}

public final class UserView: UIView {
    
    public enum ButtonState {
        case none, loading, follow, request, pending, unfollow, blocked
    }
    
    private var currentButtonState: ButtonState = .none
    public static var metricFormatter = MastodonMetricFormatter()

    public weak var delegate: UserViewDelegate?
    
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
        label.setContentCompressionResistancePriority(.defaultHigh - 2, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular)),
            .foregroundColor: UIColor.secondaryLabel
        ]
        label.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold)),
            .foregroundColor: Asset.Colors.Brand.blurple.color
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

    public let followButtonWrapper = UIView()
    public let followButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.background.cornerRadius = 10

        let button = UIButton(configuration: buttonConfiguration)
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
            
    public func prepareForReuse() {
        disposeBag.removeAll()
        
        // viewModel.objects.removeAll()
        viewModel.authorAvatarImageURL = nil
        
        avatarButton.avatarImageView.cancelTask()
        setButtonState(.none)
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

        avatarButton.setContentHuggingPriority(.defaultLow, for: .vertical)
        avatarButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // label container
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        containerStackView.addArrangedSubview(labelStackView)
        
        // follow button
        followButtonWrapper.translatesAutoresizingMaskIntoConstraints = false
        followButtonWrapper.addSubview(followButton)

        containerStackView.addArrangedSubview(followButtonWrapper)

        NSLayoutConstraint.activate([
            followButton.topAnchor.constraint(lessThanOrEqualTo: avatarButton.topAnchor),
            followButton.leadingAnchor.constraint(equalTo: followButtonWrapper.leadingAnchor),
            followButtonWrapper.trailingAnchor.constraint(equalTo: followButton.trailingAnchor),
            followButtonWrapper.bottomAnchor.constraint(greaterThanOrEqualTo: followButton.bottomAnchor),

            followButtonWrapper.heightAnchor.constraint(equalTo: containerStackView.heightAnchor),
        ])
        
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

        NSLayoutConstraint.activate([
            avatarButton.heightAnchor.constraint(lessThanOrEqualToConstant: 56),
            avatarButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
            avatarButton.heightAnchor.constraint(equalTo: avatarButton.widthAnchor),
            avatarButton.heightAnchor.constraint(equalTo: labelStackView.heightAnchor),
        ])
        
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

public extension UserView {
    private func prepareButtonStateLayout(for state: ButtonState) {
        switch state {
        case .none:
            verifiedStackView.axis = .horizontal
            verifiedStackView.alignment = .leading
            verifiedStackCenterSpacerView.isHidden = false
            followButton.isHidden = true
        default:
            verifiedStackView.axis = .vertical
            verifiedStackView.alignment = .leading
            verifiedStackCenterSpacerView.isHidden = true
            followButton.isHidden = false
        }
    }
    
    @objc private func didTapFollowButton() {
        if let account = viewModel.account {
            delegate?.userView(self, didTapButtonWith: currentButtonState, for: account, me: nil)
        }
    }

    func updateButtonState(with relationship: Mastodon.Entity.Relationship?, isMe: Bool) {
        let buttonState: UserView.ButtonState
        
        if let relationship {
            if isMe {
                buttonState = .none
            } else if relationship.following {
                buttonState = .unfollow
            } else if relationship.blocking || relationship.domainBlocking {
                buttonState = .blocked
            } else if relationship.requested {
                buttonState = .pending
            } else {
                buttonState = .follow
            }
        } else {
            buttonState = .none
        }

        setButtonState(buttonState)

    }

    func setButtonState(_ state: ButtonState) {
        currentButtonState = state
        prepareButtonStateLayout(for: state)

        switch state {

            case .loading:
                followButtonWrapper.isHidden = false
                followButton.isHidden = false
                followButton.configuration?.title = nil
                followButton.configuration?.showsActivityIndicator = true
                followButton.configuration?.background.backgroundColor = Asset.Colors.Button.userFollowing.color
                followButton.configuration?.baseForegroundColor = Asset.Colors.Brand.blurple.color
                followButton.isEnabled = false

            case .follow:
                followButtonWrapper.isHidden = false
                followButton.isHidden = false
                followButton.configuration?.title = L10n.Common.Controls.Friendship.follow
                followButton.configuration?.showsActivityIndicator = false
                followButton.configuration?.background.backgroundColor = Asset.Colors.Button.userFollow.color
                followButton.configuration?.baseForegroundColor = .white
                followButton.isEnabled = true

            case .request:
                followButtonWrapper.isHidden = false
                followButton.isHidden = false
                followButton.configuration?.title = L10n.Common.Controls.Friendship.request
                followButton.configuration?.showsActivityIndicator = false
                followButton.configuration?.background.backgroundColor = Asset.Colors.Button.userFollow.color
                followButton.configuration?.baseForegroundColor = .white
                followButton.isEnabled = true

            case .pending:
                followButtonWrapper.isHidden = false
                followButton.isHidden = false
                followButton.configuration?.title = L10n.Common.Controls.Friendship.pending
                followButton.configuration?.baseForegroundColor = Asset.Colors.Button.userFollowingTitle.color
                followButton.configuration?.showsActivityIndicator = false
                followButton.configuration?.background.backgroundColor = Asset.Colors.Button.userFollowing.color
                followButton.isEnabled = true

            case .unfollow:
                followButtonWrapper.isHidden = false
                followButton.isHidden = false
                followButton.configuration?.title = L10n.Common.Controls.Friendship.following
                followButton.configuration?.showsActivityIndicator = false
                followButton.configuration?.background.backgroundColor = Asset.Colors.Button.userFollowing.color
                followButton.configuration?.baseForegroundColor = Asset.Colors.Button.userFollowingTitle.color
                followButton.isEnabled = true

            case .blocked:
                followButtonWrapper.isHidden = false
                followButton.isHidden = false
                followButton.configuration?.title = L10n.Common.Controls.Friendship.blocked
                followButton.configuration?.showsActivityIndicator = false
                followButton.configuration?.background.backgroundColor = Asset.Colors.Button.userBlocked.color
                followButton.configuration?.baseForegroundColor = .systemRed
                followButton.isEnabled = true

            case .none:
                followButtonWrapper.isHidden = true
                followButton.isHidden = true
                followButton.configuration?.title = nil
                followButton.configuration?.showsActivityIndicator = false
                followButton.configuration?.background.backgroundColor = .clear
                followButton.isEnabled = false
        }

        followButton.addTarget(self, action: #selector(didTapFollowButton), for: .touchUpInside)
        followButton.titleLabel?.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .boldSystemFont(ofSize: 15))
    }
}

