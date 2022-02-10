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

final class RemoteProfileViewModel: ProfileViewModel {
    
    init(context: AppContext, userID: Mastodon.Entity.Account.ID) {
        super.init(context: context, optionalMastodonUser: nil)
        
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let domain = activeMastodonAuthenticationBox.domain
        let authorization = activeMastodonAuthenticationBox.userAuthorization
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
    
    init(context: AppContext, notificationID: Mastodon.Entity.Notification.ID) {
        super.init(context: context, optionalMastodonUser: nil)

        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let domain = activeMastodonAuthenticationBox.domain
        let authorization = activeMastodonAuthenticationBox.userAuthorization

//        context.apiService.notification(
//            notificationID: notificationID,
//            mastodonAuthenticationBox: activeMastodonAuthenticationBox
//        )
//        .compactMap { [weak self] response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>? in
//            let userID = response.value.account.id
//            // TODO: use .account directly
//            return context.apiService.accountInfo(
//                domain: domain,
//                userID: userID,
//                authorization: authorization
//            )
//        }
//        .switchToLatest()
//        .retry(3)
//        .sink { completion in
//            switch completion {
//            case .failure(let error):
//                // TODO: handle error
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote notification %s user fetch failed: %s", ((#file as NSString).lastPathComponent), #line, #function, notificationID, error.localizedDescription)
//            case .finished:
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: remote notification %s user fetched", ((#file as NSString).lastPathComponent), #line, #function, notificationID)
//            }
//        } receiveValue: { [weak self] response in
//            guard let self = self else { return }
//            let managedObjectContext = context.managedObjectContext
//            let request = MastodonUser.sortedFetchRequest
//            request.fetchLimit = 1
//            request.predicate = MastodonUser.predicate(domain: domain, id: response.value.id)
//            guard let mastodonUser = managedObjectContext.safeFetch(request).first else {
//                assertionFailure()
//                return
//            }
//            self.mastodonUser.value = mastodonUser
//        }
//        .store(in: &disposeBag)
    }
    
}
