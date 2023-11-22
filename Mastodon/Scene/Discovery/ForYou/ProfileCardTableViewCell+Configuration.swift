//
//  ProfileCardTableViewCell+Configuration.swift
//  
//
//  Created by MainasuK on 2022-4-19.
//

import UIKit
import MastodonSDK

extension ProfileCardTableViewCell {
    
    public func configure(
        tableView: UITableView,
        account: Mastodon.Entity.Account,
        relationship: Mastodon.Entity.Relationship?,
        profileCardTableViewCellDelegate: ProfileCardTableViewCellDelegate?
    ) {
        if profileCardView.frame == .zero {
            // set content view width
            assert(layoutMarginsGuide.layoutFrame.width > .zero)
            shadowBackgroundContainer.frame.size.width = layoutMarginsGuide.layoutFrame.width
            profileCardView.setupLayoutFrame(layoutMarginsGuide.layoutFrame)
        }

        profileCardView.configure(account: account, relationship: relationship)
        delegate = profileCardTableViewCellDelegate
    }

}
