//
//  StatusProvider+StatusTableViewCellDelegate.swift
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
        guard let item = item(for: cell, indexPath: nil) else { return }
            
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
    
}

extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int) {
        
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapContentWarningVisualEffectView visualEffectView: UIVisualEffectView) {
        guard let diffableDataSource = self.tableViewDiffableDataSource else { return }
        guard let item = item(for: cell, indexPath: nil) else { return }
        
        switch item {
        case .homeTimelineIndex(_, let attribute):
            attribute.isStatusSensitive = false
        case .toot(_, let attribute):
            attribute.isStatusSensitive = false
        default:
            return
        }
        
        var snapshot = diffableDataSource.snapshot()
        snapshot.reloadItems([item])
        UIView.animate(withDuration: 0.33) {
            cell.statusView.statusMosaicImageViewContainer.blurVisualEffectView.effect = nil
            cell.statusView.statusMosaicImageViewContainer.vibrancyVisualEffectView.alpha = 0.0
        } completion: { _ in
            diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
    }
    
}
