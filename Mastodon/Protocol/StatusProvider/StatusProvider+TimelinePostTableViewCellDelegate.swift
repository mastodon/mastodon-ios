//
//  StatusProvider+TimelinePostTableViewCellDelegate.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/8.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import ActiveLabel

// MARK: - ActionToolbarContainerDelegate
extension TimelinePostTableViewCellDelegate where Self: StatusProvider {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusLikeAction(provider: self, cell: cell)
    }
    
    
}
