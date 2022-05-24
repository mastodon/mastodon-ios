//
//  ProfileCardTableViewCell+Configuration.swift
//  
//
//  Created by MainasuK on 2022-4-19.
//

import UIKit
import CoreDataStack
import MastodonSDK

extension ProfileCardTableViewCell {
    
    public func configure(
        tableView: UITableView,
        user: MastodonUser,
        profileCardTableViewCellDelegate: ProfileCardTableViewCellDelegate?
    ) {
        if profileCardView.frame == .zero {
            // set content view width
            assert(layoutMarginsGuide.layoutFrame.width > .zero)
            shadowBackgroundContainer.frame.size.width = layoutMarginsGuide.layoutFrame.width
            profileCardView.setupLayoutFrame(layoutMarginsGuide.layoutFrame)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did layout for new cell")
        }
        
        profileCardView.configure(user: user)
        delegate = profileCardTableViewCellDelegate
    }
    
}
