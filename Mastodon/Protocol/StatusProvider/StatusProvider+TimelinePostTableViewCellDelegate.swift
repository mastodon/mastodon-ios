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

extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int) {
        
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapContentWarningVisualEffectView visualEffectView: UIVisualEffectView) {
        guard let diffableDataSource = self.tableViewDiffableDataSource else { return }
        item(for: cell, indexPath: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let _ = self else { return }
                guard let item = item else { return }
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
                    cell.statusView.statusMosaicImageView.blurVisualEffectView.effect = nil
                    cell.statusView.statusMosaicImageView.vibrancyVisualEffectView.alpha = 0.0
                } completion: { _ in
                    diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
                }
            }
            .store(in: &cell.disposeBag)
    }
    
}
