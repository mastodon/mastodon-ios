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
            authorizationBox: authorizationBox
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            switch completion {
            case .failure(let error):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch user timeline fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                guard let self = self else { return }
                guard let reportStatusId = self.statusId else { return }
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
            if let reportStatusId = self.statusId, !statusIDs.contains(reportStatusId) {
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
                    if status.id == self.statusId {
                        attribute.isSelected = true
                        self.append(statusID: status.id)
                        self.continueEnableSubject.send(true)
                    }
                }
                snapshot.appendItems(items, toSection: .main)
            }
            .store(in: &disposeBag)
    }
}
