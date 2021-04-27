//
//  ReportViewModel+Data.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import os.log

extension ReportViewModel {
    func requestRecentStatus(
        domain: String,
        accountId: String,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) {
        context.apiService.userTimeline(
            domain: domain,
            accountID: accountId,
            excludeReblogs: true,
            authorizationBox: authorizationBox
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            switch completion {
            case .failure(let error):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch user timeline fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                guard let self = self else { return }
                guard let reportStatusId = self.status?.id else { return }
                var statusIDs = self.statusFetchedResultsController.statusIDs.value
                guard statusIDs.contains(reportStatusId) else { return }
                
                statusIDs.append(reportStatusId)
                self.statusFetchedResultsController.statusIDs.value = statusIDs
            case .finished:
                break
            }
        } receiveValue: { [weak self] response in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
            guard let self = self else { return }
            
            var statusIDs = response.value.map { $0.id }
            if let reportStatusId = self.status?.id, !statusIDs.contains(reportStatusId) {
                statusIDs.append(reportStatusId)
            }
            
            self.statusFetchedResultsController.statusIDs.value = statusIDs
        }
        .store(in: &disposeBag)
    }
    
    func fetchStatus() {
        let managedObjectContext = self.statusFetchedResultsController.fetchedResultsController.managedObjectContext
        statusFetchedResultsController.objectIDs.eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] objectIDs in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var items: [Item] = []
                var snapshot = NSDiffableDataSourceSnapshot<ReportSection, Item>()
                snapshot.appendSections([.main])
                
                defer {
                    // not animate when empty items fix loader first appear layout issue
                    diffableDataSource.apply(snapshot, animatingDifferences: !items.isEmpty)
                }
                
                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.ReportStatusAttribute] = [:]
                let oldSnapshot = diffableDataSource.snapshot()
                for item in oldSnapshot.itemIdentifiers {
                    guard case let .reportStatus(objectID, attribute) = item else { continue }
                    oldSnapshotAttributeDict[objectID] = attribute
                }
                
                for objectID in objectIDs {
                    let attribute = oldSnapshotAttributeDict[objectID] ?? Item.ReportStatusAttribute()
                    let item = Item.reportStatus(objectID: objectID, attribute: attribute)
                    items.append(item)
                    
                    guard let status = managedObjectContext.object(with: objectID) as? Status else {
                        continue
                    }
                    if status.id == self.status?.id {
                        attribute.isSelected = true
                        self.append(statusID: status.id)
                        self.continueEnableSubject.send(true)
                    }
                }
                snapshot.appendItems(items, toSection: .main)
            }
            .store(in: &disposeBag)
    }
    
    func prefetchData(prefetchRowsAt indexPaths: [IndexPath]) {
        guard let diffableDataSource = diffableDataSource else { return }
        
        // prefetch reply status
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        let domain = activeMastodonAuthenticationBox.domain
        
        var statusObjectIDs: [NSManagedObjectID] = []
        for indexPath in indexPaths {
            let item = diffableDataSource.itemIdentifier(for: indexPath)
            switch item {
            case .reportStatus(let objectID, _):
                statusObjectIDs.append(objectID)
            default:
                continue
            }
        }
        
        let backgroundManagedObjectContext = context.backgroundManagedObjectContext
        backgroundManagedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            for objectID in statusObjectIDs {
                let status = backgroundManagedObjectContext.object(with: objectID) as! Status
                guard let replyToID = status.inReplyToID, status.replyTo == nil else {
                    // skip
                    continue
                }
                self.context.statusPrefetchingService.prefetchReplyTo(
                    domain: domain,
                    statusObjectID: status.objectID,
                    statusID: status.id,
                    replyToStatusID: replyToID,
                    authorizationBox: activeMastodonAuthenticationBox
                )
            }
        }
    }
}
