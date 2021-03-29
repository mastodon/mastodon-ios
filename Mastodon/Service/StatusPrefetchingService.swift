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

final class StatusPrefetchingService {
    
    typealias TaskID = String
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.Mastodon.StatusPrefetchingService.working-queue")

    var disposeBag = Set<AnyCancellable>()
    private(set) var statusPrefetchingDisposeBagDict: [TaskID: AnyCancellable] = [:]
    
    weak var apiService: APIService?
    
    init(apiService: APIService) {
        self.apiService = apiService
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
                    guard let status = backgroundManagedObjectContext.object(with: statusObjectID) as? Toot else { return }
                    do {
                        let predicate = Toot.predicate(domain: domain, id: replyToStatusID)
                        let request = Toot.sortedFetchRequest
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
