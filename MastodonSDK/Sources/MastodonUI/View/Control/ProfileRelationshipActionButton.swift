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
    public func configure(relationship: Mastodon.Entity.Relationship?, between account: Mastodon.Entity.Account, and me: Mastodon.Entity.Account, isEditing: Bool = false, isUpdating: Bool = false) {

        let isMyself = (account == me)

        var configuration = UIButton.Configuration.filled()

        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        configuration.baseBackgroundColor = Asset.Scene.Profile.RelationshipButton.background.color
        configuration.activityIndicatorColorTransformer = UIConfigurationColorTransformer({ _ in return Asset.Colors.Label.primaryReverse.color })
        configuration.background.cornerRadius = 10

        let title: String

        switch (isMyself, isUpdating, relationship) {
        case (true, _, _):
            if isEditing {
                title = L10n.Common.Controls.Actions.save
            } else {
                title = L10n.Common.Controls.Friendship.editInfo
            }
            configuration.showsActivityIndicator = false
        case (_, true, _):
            title = ""
            configuration.showsActivityIndicator = true
        case (false, false, .some(let relationship)):
            configuration.showsActivityIndicator = false

            if relationship.blocking {
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
        case (_, _, nil):
            title = ""
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
