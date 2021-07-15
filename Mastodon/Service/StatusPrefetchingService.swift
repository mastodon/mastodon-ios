//
//  StatusPrefetchingService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonMeta

final class StatusPrefetchingService {
    
    typealias TaskID = String
    typealias StatusObjectID = NSManagedObjectID
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.StatusPrefetchingService.working-queue")

    // StatusContentOperation
    let statusContentOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "org.joinmastodon.app.StatusPrefetchingService.statusContentOperationQueue"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    var statusContentOperations: [StatusObjectID: StatusContentOperation] = [:]

    var disposeBag = Set<AnyCancellable>()
    private(set) var statusPrefetchingDisposeBagDict: [TaskID: AnyCancellable] = [:]

    // input
    weak var apiService: APIService?
    let managedObjectContext: NSManagedObjectContext
    let backgroundManagedObjectContext: NSManagedObjectContext  // read-only
    
    init(
        managedObjectContext: NSManagedObjectContext,
        backgroundManagedObjectContext: NSManagedObjectContext,
        apiService: APIService
    ) {
        self.managedObjectContext = managedObjectContext
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.apiService = apiService
    }

    private func status(from statusObjectItem: StatusObjectItem) -> Status? {
        assert(Thread.isMainThread)
        switch statusObjectItem {
        case .homeTimelineIndex(let objectID):
            let homeTimelineIndex = try? managedObjectContext.existingObject(with: objectID) as? HomeTimelineIndex
            return homeTimelineIndex?.status
        case .mastodonNotification(let objectID):
            let mastodonNotification = try? managedObjectContext.existingObject(with: objectID) as? MastodonNotification
            return mastodonNotification?.status
        case .status(let objectID):
            let status = try? managedObjectContext.existingObject(with: objectID) as? Status
            return status
        }

    }
    
}

extension StatusPrefetchingService {
    func prefetch(statusObjectItems items: [StatusObjectItem]) {
        for item in items {
            guard let status = status(from: item), !status.isDeleted else { continue }

            // status content parser task
            if statusContentOperations[status.objectID] == nil {
                let mastodonContent = MastodonContent(
                    content: (status.reblog ?? status).content,
                    emojis: (status.reblog ?? status).emojiMeta
                )
                let operation = StatusContentOperation(
                    statusObjectID: status.objectID,
                    mastodonContent: mastodonContent
                )
                statusContentOperations[status.objectID] = operation
                statusContentOperationQueue.addOperation(operation)
            }
        }
    }

    func cancelPrefetch(statusObjectItems items: [StatusObjectItem]) {
        for item in items {
            guard let status = status(from: item), !status.isDeleted else { continue }

            // cancel status content parser task
            statusContentOperations.removeValue(forKey: status.objectID)?.cancel()
        }
    }

}

extension StatusPrefetchingService {
    
    func prefetchReplyTo(
        domain: String,
        statusObjectID: NSManagedObjectID,
        statusID: Mastodon.Entity.Status.ID,
        replyToStatusID: Mastodon.Entity.Status.ID,
        authorizationBox: AuthenticationService.MastodonAuthenticationBox
    ) {
        workingQueue.async { [weak self] in
            guard let self = self, let apiService = self.apiService else { return }
            let taskID = domain + "@" + statusID + "->" + replyToStatusID
            guard self.statusPrefetchingDisposeBagDict[taskID] == nil else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: prefetching replyTo: %s", ((#file as NSString).lastPathComponent), #line, #function, taskID)
            
            self.statusPrefetchingDisposeBagDict[taskID] = apiService.status(
                domain: domain,
                statusID: replyToStatusID,
                authorizationBox: authorizationBox
            )
            .sink(receiveCompletion: { [weak self] completion in
                // remove task when completed
                guard let self = self else { return }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: prefeched replyTo: %s", ((#file as NSString).lastPathComponent), #line, #function, taskID)
                self.statusPrefetchingDisposeBagDict[taskID] = nil
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                let backgroundManagedObjectContext = apiService.backgroundManagedObjectContext
                backgroundManagedObjectContext.performChanges {
                    guard let status = backgroundManagedObjectContext.object(with: statusObjectID) as? Status else { return }
                    do {
                        let predicate = Status.predicate(domain: domain, id: replyToStatusID)
                        let request = Status.sortedFetchRequest
                        request.predicate = predicate
                        request.returnsObjectsAsFaults = false
                        request.fetchLimit = 1
                        guard let replyTo = try backgroundManagedObjectContext.fetch(request).first else { return }
                        status.update(replyTo: replyTo)
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                .sink { _ in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update status replyTo: %s", ((#file as NSString).lastPathComponent), #line, #function, taskID)
                } receiveValue: { _ in
                    // do nothing
                }
                .store(in: &self.disposeBag)
            })
        }
    }
    
}
