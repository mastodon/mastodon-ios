//
//  HomeTimelineViewController+DebugAction.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

#if DEBUG
extension HomeTimelineViewController {
    var debugMenu: UIMenu {
        let menu = UIMenu(
            title: "Debug Tools",
            image: nil,
            identifier: nil,
            options: .displayInline,
            children: [
                dropMenu,
                UIAction(title: "Show Public Timeline", image: UIImage(systemName: "list.dash"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showPublicTimelineAction(action)
                },
                UIAction(title: "Sign Out", image: UIImage(systemName: "escape"), attributes: .destructive) { [weak self] action in
                    guard let self = self else { return }
                    self.signOutAction(action)
                }
            ]
        )
        return menu
    }
    
    var dropMenu: UIMenu {
        return UIMenu(
            title: "Drop…",
            image: UIImage(systemName: "minus.circle"),
            identifier: nil,
            options: [],
            children: [50, 100, 150, 200, 250, 300].map { count in
                UIAction(title: "Drop Recent \(count) Tweets", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.dropRecentTweetsAction(action, count: count)
                })
            }
        )
    }
}

extension HomeTimelineViewController {
    
    @objc private func dropRecentTweetsAction(_ sender: UIAction, count: Int) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        
        let droppingObjectIDs = snapshotTransitioning.itemIdentifiers.prefix(count).compactMap { item -> NSManagedObjectID? in
            switch item {
            case .homeTimelineIndex(let objectID, _):   return objectID
            default:                                    return nil
            }
        }
        var droppingTootObjectIDs: [NSManagedObjectID] = []
        context.apiService.backgroundManagedObjectContext.performChanges { [weak self] in
            guard let self = self else { return }
            for objectID in droppingObjectIDs {
                guard let homeTimelineIndex = try? self.context.apiService.backgroundManagedObjectContext.existingObject(with: objectID) as? HomeTimelineIndex else { continue }
                droppingTootObjectIDs.append(homeTimelineIndex.toot.objectID)
                self.context.apiService.backgroundManagedObjectContext.delete(homeTimelineIndex)
            }
        }
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.context.apiService.backgroundManagedObjectContext.performChanges { [weak self] in
                    guard let self = self else { return }
                    for objectID in droppingTootObjectIDs {
                        guard let toot = try? self.context.apiService.backgroundManagedObjectContext.existingObject(with: objectID) as? Toot else { continue }
                        self.context.apiService.backgroundManagedObjectContext.delete(toot)
                    }
                }
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
        .store(in: &disposeBag)
    }
    
    @objc private func showPublicTimelineAction(_ sender: UIAction) {
        coordinator.present(scene: .publicTimeline, from: self, transition: .show)
    }
    
}
#endif
