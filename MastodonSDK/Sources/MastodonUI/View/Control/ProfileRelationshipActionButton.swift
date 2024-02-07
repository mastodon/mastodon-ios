//
//  ProfileRelationshipActionButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import MastodonAsset
import MastodonLocalization

public final class ProfileRelationshipActionButton: UIButton {
    public func configure(actionOptionSet: RelationshipActionOptionSet) {

        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = AttributedString(
            actionOptionSet.title,
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: Asset.Colors.Label.primaryReverse.color
            ])
        )

        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        configuration.baseBackgroundColor = Asset.Scene.Profile.RelationshipButton.background.color
        configuration.background.cornerRadius = 10

        if let option = actionOptionSet.highPriorityAction(except: .editOptions), option == .blocked || option == .suspended {
            isEnabled = false
        } else if actionOptionSet.contains(.updating) {
            isEnabled = false
            configuration.showsActivityIndicator = true
        } else {
            isEnabled = true
        }

        self.configuration = configuration
    }
}
