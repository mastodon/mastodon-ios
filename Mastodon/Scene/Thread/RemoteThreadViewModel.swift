//
//  RemoteThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import UIKit
import CoreDataStack
import MastodonSDK

final class RemoteThreadViewModel: ThreadViewModel {
        
    init(context: AppContext, statusID: Mastodon.Entity.Status.ID) {
        super.init(context: context, optionalStatus: nil)
        
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let domain = activeMastodonAuthenticationBox.domain
        context.apiService.status(
            domain: domain,
            statusID: statusID,
            authorizationBox: activeMastodonAuthenticationBox
        )
        .retry(3)
        .sink { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote status %s fetch failed: %s", ((#file as NSString).lastPathComponent), #line, #function, statusID, error.localizedDescription)
            case .finished:
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote status %s fetched", ((#file as NSString).lastPathComponent), #line, #function, statusID)
            }
        } receiveValue: { [weak self] response in
            guard let self = self else { return }
            let managedObjectContext = context.managedObjectContext
            let request = Status.sortedFetchRequest
            request.fetchLimit = 1
            request.predicate = Status.predicate(domain: domain, id: response.value.id)
            guard let status = managedObjectContext.safeFetch(request).first else {
                assertionFailure()
                return
            }
            self.rootItem.value = .root(statusObjectID: status.objectID, attribute: Item.StatusAttribute())
        }
        .store(in: &disposeBag)
    }
    
    // FIXME: multiple account supports
    init(context: AppContext, notificationID: Mastodon.Entity.Notification.ID) {
        super.init(context: context, optionalStatus: nil)
        
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let domain = activeMastodonAuthenticationBox.domain
        context.apiService.notification(
            notificationID: notificationID,
            mastodonAuthenticationBox: activeMastodonAuthenticationBox
        )
        .retry(3)
        .sink { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote notification %s fetch failed: %s", ((#file as NSString).lastPathComponent), #line, #function, notificationID, error.localizedDescription)
            case .finished:
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote notification %s fetched", ((#file as NSString).lastPathComponent), #line, #function, notificationID)
            }
        } receiveValue: { [weak self] response in
            guard let self = self else { return }
            guard let statusID = response.value.status?.id else { return }
            
            let managedObjectContext = context.managedObjectContext
            let request = Status.sortedFetchRequest
            request.fetchLimit = 1
            request.predicate = Status.predicate(domain: domain, id: statusID)
            guard let status = managedObjectContext.safeFetch(request).first else {
                assertionFailure()
                return
            }
            self.rootItem.value = .root(statusObjectID: status.objectID, attribute: Item.StatusAttribute())
        }
        .store(in: &disposeBag)
    }
    
}
