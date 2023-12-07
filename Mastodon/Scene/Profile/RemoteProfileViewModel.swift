//
//  RemoteProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import Foundation
import Combine
import CoreDataStack
import MastodonSDK
import MastodonCore

final class RemoteProfileViewModel: ProfileViewModel {
    
    @MainActor
    init(context: AppContext, authContext: AuthContext, userID: Mastodon.Entity.Account.ID) {
        super.init(context: context, authContext: authContext, account: nil)
        
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
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(_):
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                self?.account = response.value
            }
            .store(in: &disposeBag)
    }
    
    @MainActor
    init(context: AppContext, authContext: AuthContext, notificationID: Mastodon.Entity.Notification.ID) {
        super.init(context: context, authContext: authContext, account: nil)

        Task { @MainActor in
            let response = try await context.apiService.notification(
                notificationID: notificationID,
                authenticationBox: authContext.mastodonAuthenticationBox
            )

            self.account = response.value.account
        }   // end Task
    }
    
    @MainActor
    init(context: AppContext, authContext: AuthContext, acct: String){
        super.init(context: context, authContext: authContext, account: nil)

        let domain = authContext.mastodonAuthenticationBox.domain
        let authenticationBox = authContext.mastodonAuthenticationBox

        Just(acct)
            .asyncMap { acct -> Mastodon.Response.Content<Mastodon.Entity.Account?> in
                try await context.apiService.search(
                    query: .init(q: acct, type: .accounts, resolve: true),
                    authenticationBox: authenticationBox
                ).map { $0.accounts.first }
            }
            .retry(3)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(_):
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let account = response.value else { return }

                self?.account = account
            }
            .store(in: &disposeBag)
    }
}
