//
//  RemoteProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import MastodonSDK
import MastodonCore

final class RemoteProfileViewModel: ProfileViewModel {
    
    init(context: AppContext, authContext: AuthContext, userID: Mastodon.Entity.Account.ID) {
        super.init(context: context, authContext: authContext, optionalMastodonUser: nil)
        
        let domain = authContext.mastodonAuthenticationBox.domain
        let authorization = authContext.mastodonAuthenticationBox.userAuthorization
        Just(userID)
            .asyncMap { userID in
                try await context.apiService.accountInfo(
                    domain: domain,
                    userID: userID,
                    authorization: authorization
                )
            }
            .retry(3)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    // TODO: handle error
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote user %s fetch failed: %s", ((#file as NSString).lastPathComponent), #line, #function, userID, error.localizedDescription)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote user %s fetched", ((#file as NSString).lastPathComponent), #line, #function, userID)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let managedObjectContext = context.managedObjectContext
                let request = MastodonUser.sortedFetchRequest
                request.fetchLimit = 1
                request.predicate = MastodonUser.predicate(domain: domain, id: response.value.id)
                guard let mastodonUser = managedObjectContext.safeFetch(request).first else {
                    assertionFailure()
                    return
                }
                self.user = mastodonUser
            }
            .store(in: &disposeBag)
    }
    
    init(context: AppContext, authContext: AuthContext, notificationID: Mastodon.Entity.Notification.ID) {
        super.init(context: context, authContext: authContext, optionalMastodonUser: nil)

        Task { @MainActor in
            let response = try await context.apiService.notification(
                notificationID: notificationID,
                authenticationBox: authContext.mastodonAuthenticationBox
            )
            let userID = response.value.account.id
            
            let _user: MastodonUser? = try await context.managedObjectContext.perform {
                let request = MastodonUser.sortedFetchRequest
                request.predicate = MastodonUser.predicate(domain: authContext.mastodonAuthenticationBox.domain, id: userID)
                request.fetchLimit = 1
                return context.managedObjectContext.safeFetch(request).first
            }
            
            if let user = _user {
                self.user = user
            } else {
                _ = try await context.apiService.accountInfo(
                    domain: authContext.mastodonAuthenticationBox.domain,
                    userID: userID,
                    authorization: authContext.mastodonAuthenticationBox.userAuthorization
                )
                
                let _user: MastodonUser? = try await context.managedObjectContext.perform {
                    let request = MastodonUser.sortedFetchRequest
                    request.predicate = MastodonUser.predicate(domain: authContext.mastodonAuthenticationBox.domain, id: userID)
                    request.fetchLimit = 1
                    return context.managedObjectContext.safeFetch(request).first
                }
                
                self.user = _user
            }
        }   // end Task
    }
    
}
