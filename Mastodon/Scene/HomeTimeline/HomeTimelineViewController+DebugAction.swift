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
                moveMenu,
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
    
    var moveMenu: UIMenu {
        return UIMenu(
            title: "Move to…",
            image: UIImage(systemName: "arrow.forward.circle"),
            identifier: nil,
            options: [],
            children: [
                UIAction(title: "First Gap", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToTopGapAction(action)
                }),
                UIAction(title: "First Replied Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstRepliedStatus(action)
                }),
                UIAction(title: "First Reblog Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstReblogStatus(action)
                }),
                UIAction(title: "First Poll Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstPollStatus(action)
                }),
                UIAction(title: "First Audio Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstAudioStatus(action)
                }),
                UIAction(title: "First Video Status", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstVideoStatus(action)
                }),
                UIAction(title: "First GIF Toot", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.moveToFirstGIFStatus(action)
                }),
            ]
        )
    }
    
    var dropMenu: UIMenu {
        return UIMenu(
            title: "Drop…",
            image: UIImage(systemName: "minus.circle"),
            identifier: nil,
            options: [],
            children: [50, 100, 150, 200, 250, 300].map { count in
                UIAction(title: "Drop Recent \(count) Statuses", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.dropRecentStatusAction(action, count: count)
                })
            }
        )
    }
}

extension HomeTimelineViewController {
    
    @objc private func moveToTopGapAction(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeMiddleLoader:         return true
            default:                        return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
    }
    
    @objc private func moveToFirstReblogStatus(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let homeTimelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                return homeTimelineIndex.toot.reblog != nil
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found reblog status")
        }
    }
    
    @objc private func moveToFirstPollStatus(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let homeTimelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                let post = homeTimelineIndex.toot.reblog ?? homeTimelineIndex.toot
                return post.poll != nil
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found poll status")
        }
    }
    
    @objc private func moveToFirstRepliedStatus(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let homeTimelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                guard homeTimelineIndex.toot.inReplyToID != nil else {
                    return false
                }
                return true
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found replied status")
        }
    }
    
    @objc private func moveToFirstAudioStatus(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let homeTimelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                let toot = homeTimelineIndex.toot.reblog ?? homeTimelineIndex.toot
                return toot.mediaAttachments?.contains(where: { $0.type == .audio }) ?? false
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found audio toot")
        }
    }
    
    @objc private func moveToFirstVideoStatus(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let homeTimelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                let toot = homeTimelineIndex.toot.reblog ?? homeTimelineIndex.toot
                return toot.mediaAttachments?.contains(where: { $0.type == .video }) ?? false
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found video status")
        }
    }
    
    @objc private func moveToFirstGIFStatus(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshotTransitioning = diffableDataSource.snapshot()
        let item = snapshotTransitioning.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let homeTimelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                let toot = homeTimelineIndex.toot.reblog ?? homeTimelineIndex.toot
                return toot.mediaAttachments?.contains(where: { $0.type == .gifv }) ?? false
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshotTransitioning.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            tableView.blinkRow(at: IndexPath(row: index, section: 0))
        } else {
            print("Not found GIF status")
        }
    }
    
    @objc private func dropRecentStatusAction(_ sender: UIAction, count: Int) {
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
                        guard let post = try? self.context.apiService.backgroundManagedObjectContext.existingObject(with: objectID) as? Toot else { continue }
                        self.context.apiService.backgroundManagedObjectContext.delete(post)
                    }
                }
                .sink { _ in
                    // do nothing
                }
                .store(in: &self.disposeBag)
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
