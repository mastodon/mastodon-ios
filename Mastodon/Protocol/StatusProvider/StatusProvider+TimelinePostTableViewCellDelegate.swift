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
extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusLikeAction(provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, contentWarningActionButtonPressed button: UIButton) {
        guard let diffableDataSource = self.tableViewDiffableDataSource else { return }
        item(for: cell, indexPath: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let _ = self else { return }
                guard let item = item else { return }
                switch item {
                case .homeTimelineIndex(_, let attribute):
                    attribute.isStatusTextSensitive = false
                case .toot(_, let attribute):
                    attribute.isStatusTextSensitive = false
                default:
                    return
                }
                var snapshot = diffableDataSource.snapshot()
                snapshot.reloadItems([item])
                diffableDataSource.apply(snapshot)
            }
            .store(in: &cell.disposeBag)
    }
    
}
