//
//  ProfileRelationshipActionButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import MastodonAsset
import MastodonSDK
import MastodonLocalization

public final class ProfileRelationshipActionButton: RoundedEdgesButton {
    
    public let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.color = Asset.Colors.Label.primaryReverse.color
        return activityIndicatorView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileRelationshipActionButton {
    private func _init() {
        cornerRadius = 10
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
        
        configureAppearance()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configureAppearance()
    }
}

extension ProfileRelationshipActionButton {

    public func configure(relationship: Mastodon.Entity.Relationship, between account: Mastodon.Entity.Account, and me: Mastodon.Entity.Account, isEditing: Bool = false, isUpdating: Bool = false) {

        let isMyself = (account == me)
        let title: String

        if isMyself {
            if isEditing {
                title = L10n.Common.Controls.Actions.save
            } else {
                title = L10n.Common.Controls.Friendship.editInfo
            }
        } else if relationship.blocking {
            title = L10n.Common.Controls.Friendship.blocked
        } else if relationship.domainBlocking {
            #warning("Wait for #1198 (Domain Block, IOS-5) to be merged")
            title = "Unblock domain"
        } else if relationship.requested {
            title = L10n.Common.Controls.Friendship.pending
        } else if relationship.muting {
            title = L10n.Common.Controls.Friendship.muted
        } else if relationship.following {
            title = L10n.Common.Controls.Friendship.following
        } else if account.locked {
            title = L10n.Common.Controls.Friendship.request
        } else {
            title = L10n.Common.Controls.Friendship.follow
        }

        setTitle(title, for: .normal)

        if relationship.blockedBy || account.suspended ?? false {
            isEnabled = false
        } else {
            isEnabled = true
        }
    }

    private func configureAppearance() {
        setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
        setTitleColor(Asset.Colors.Label.primaryReverse.color.withAlphaComponent(0.5), for: .highlighted)
        setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.background.color), for: .normal)
        setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlighted.color), for: .highlighted)
        setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlighted.color), for: .disabled)
    }
}
