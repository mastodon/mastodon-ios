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

// MARK: - MosciaImageViewContainerDelegate
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

// MARK: - PollTableView
extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func statusTableViewCell(_ cell: StatusTableViewCell, pollTableView: PollTableView, didSelectRowAt indexPath: IndexPath) {
        guard let activeMastodonAuthentication = context.authenticationService.activeMastodonAuthentication.value else { return }
        
        guard let diffableDataSource = cell.statusView.pollTableViewDataSource else { return }
        let item = diffableDataSource.itemIdentifier(for: indexPath)
        guard case let .opion(objectID, attribute) = item else { return }
        guard let option = managedObjectContext.object(with: objectID) as? PollOption else { return }
        
        
        if option.poll.multiple {
            var choices: [Int] = []
            
        } else {
            context.apiService.vote(
                pollObjectID: option.poll.objectID,
                mastodonUserObjectID: activeMastodonAuthentication.user.objectID,
                choices: [option.index.intValue]
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { pollID in
                
            }
            .store(in: &context.disposeBag)

        }
    }
    
}
