//
//  BlockDomainService.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/29.
//

import CoreData
import CoreDataStack
import Foundation
import Combine
import MastodonSDK
import OSLog
import UIKit

final class BlockDomainService {
    let userProvider: UserProvider
    let cell: UITableViewCell?
    let indexPath: IndexPath?
    init(userProvider: UserProvider,
         cell: UITableViewCell?,
         indexPath: IndexPath?
    ) {
        self.userProvider = userProvider
        self.cell = cell
        self.indexPath = indexPath
    }

    func blockDomain() {
        guard let activeMastodonAuthenticationBox = self.userProvider.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        guard let context = self.userProvider.context  else {
            return
        }
        var mastodonUser: AnyPublisher<MastodonUser?, Never>
        if let cell = self.cell, let indexPath = self.indexPath {
            mastodonUser = userProvider.mastodonUser(for: cell, indexPath: indexPath).eraseToAnyPublisher()
        } else {
            mastodonUser = userProvider.mastodonUser().eraseToAnyPublisher()
        }
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                return context.apiService.blockDomain(user: mastodonUser, authorizationBox: activeMastodonAuthenticationBox)
            }
            .switchToLatest()
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[String]>, Error>  in
                return context.apiService.getDomainblocks(domain: activeMastodonAuthenticationBox.domain, authorizationBox: activeMastodonAuthenticationBox)
            }
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { response in
                print(response)
            }
            .store(in: &userProvider.disposeBag)
    }
    
    func unblockDomain() {
        guard let activeMastodonAuthenticationBox = self.userProvider.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        guard let context = self.userProvider.context  else {
            return
        }
        var mastodonUser: AnyPublisher<MastodonUser?, Never>
        if let cell = self.cell, let indexPath = self.indexPath {
            mastodonUser = userProvider.mastodonUser(for: cell, indexPath: indexPath).eraseToAnyPublisher()
        } else {
            mastodonUser = userProvider.mastodonUser().eraseToAnyPublisher()
        }
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                return context.apiService.unblockDomain(user: mastodonUser, authorizationBox: activeMastodonAuthenticationBox)
            }
            .switchToLatest()
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[String]>, Error>  in
                return context.apiService.getDomainblocks(domain: activeMastodonAuthenticationBox.domain, authorizationBox: activeMastodonAuthenticationBox)
            }
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { response in
                print(response)
            }
            .store(in: &userProvider.disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
    }
}
