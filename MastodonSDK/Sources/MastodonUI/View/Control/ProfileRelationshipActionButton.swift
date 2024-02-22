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

public final class ProfileRelationshipActionButton: UIButton {
    public func configure(relationship: Mastodon.Entity.Relationship, between account: Mastodon.Entity.Account, and me: Mastodon.Entity.Account, isEditing: Bool = false, isUpdating: Bool = false) {

        let isMyself = (account == me)

        var configuration = UIButton.Configuration.filled()

        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        configuration.baseBackgroundColor = Asset.Scene.Profile.RelationshipButton.background.color
        configuration.activityIndicatorColorTransformer = UIConfigurationColorTransformer({ _ in return Asset.Colors.Label.primaryReverse.color })
        configuration.background.cornerRadius = 10

        var title: String

        if isMyself {
            if isEditing {
                title = L10n.Common.Controls.Actions.save
            } else {
                title = L10n.Common.Controls.Friendship.editInfo
            }
        } else if relationship.blocking {
            title = L10n.Common.Controls.Friendship.blocked
        } else if relationship.domainBlocking {
            title = L10n.Common.Controls.Friendship.domainBlocked
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

        if relationship.blockedBy || account.suspended ?? false {
            isEnabled = false
        } else {
            isEnabled = true
        }

        if isUpdating {
            configuration.showsActivityIndicator = true
            title = ""
        } else {
            configuration.showsActivityIndicator = false
        }

        configuration.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: Asset.Colors.Label.primaryReverse.color
            ])
        )

        self.configuration = configuration
    }
}
