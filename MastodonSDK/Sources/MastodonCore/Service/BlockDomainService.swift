//
//  BlockDomainService.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/29.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import OSLog
import UIKit

public final class BlockDomainService {
    
    // input
    weak var backgroundManagedObjectContext: NSManagedObjectContext?
    weak var authenticationService: AuthenticationService?

    // output
    let blockedDomains = CurrentValueSubject<[String], Never>([])

    init(
        backgroundManagedObjectContext: NSManagedObjectContext,
        authenticationService: AuthenticationService
    ) {
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.authenticationService = authenticationService
        
//        backgroundManagedObjectContext.perform {
//            let _blockedDomains: [DomainBlock] = {
//                let request = DomainBlock.sortedFetchRequest
//                request.predicate = DomainBlock.predicate(domain: authorizationBox.domain, userID: authorizationBox.userID)
//                request.returnsObjectsAsFaults = false
//                do {
//                    return try backgroundManagedObjectContext.fetch(request)
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                    return []
//                }
//            }()
//            self.blockedDomains.value = _blockedDomains.map(\.blockedDomain)
//        }
    }

//    func blockDomain(
//        userProvider: UserProvider,
//        cell: UITableViewCell?
//    ) {
//        guard let activeMastodonAuthenticationBox = userProvider.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
//        guard let context = userProvider.context else {
//            return
//        }
//        var mastodonUser: AnyPublisher<MastodonUser?, Never>
//        if let cell = cell {
//            mastodonUser = userProvider.mastodonUser(for: cell).eraseToAnyPublisher()
//        } else {
//            mastodonUser = userProvider.mastodonUser().eraseToAnyPublisher()
//        }
//        mastodonUser
//            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error>? in
//                guard let mastodonUser = mastodonUser else {
//                    return nil
//                }
//                return context.apiService.blockDomain(user: mastodonUser, authorizationBox: activeMastodonAuthenticationBox)
//            }
//            .switchToLatest()
//            .flatMap { _ -> AnyPublisher<Mastodon.Response.Content<[String]>, Error> in
//                context.apiService.getDomainblocks(domain: activeMastodonAuthenticationBox.domain, authorizationBox: activeMastodonAuthenticationBox)
//            }
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    break
//                case .failure(let error):
//                    print(error)
//                }
//            } receiveValue: { [weak self] response in
//                self?.blockedDomains.value = response.value
//            }
//            .store(in: &userProvider.disposeBag)
//    }
//
//    func unblockDomain(
//        userProvider: UserProvider,
//        cell: UITableViewCell?
//    ) {
//        guard let activeMastodonAuthenticationBox = userProvider.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
//        guard let context = userProvider.context else {
//            return
//        }
//        var mastodonUser: AnyPublisher<MastodonUser?, Never>
//        if let cell = cell {
//            mastodonUser = userProvider.mastodonUser(for: cell).eraseToAnyPublisher()
//        } else {
//            mastodonUser = userProvider.mastodonUser().eraseToAnyPublisher()
//        }
//        mastodonUser
//            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error>? in
//                guard let mastodonUser = mastodonUser else {
//                    return nil
//                }
//                return context.apiService.unblockDomain(user: mastodonUser, authorizationBox: activeMastodonAuthenticationBox)
//            }
//            .switchToLatest()
//            .flatMap { _ -> AnyPublisher<Mastodon.Response.Content<[String]>, Error> in
//                context.apiService.getDomainblocks(domain: activeMastodonAuthenticationBox.domain, authorizationBox: activeMastodonAuthenticationBox)
//            }
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    break
//                case .failure(let error):
//                    print(error)
//                }
//            } receiveValue: { [weak self] response in
//                self?.blockedDomains.value = response.value
//            }
//            .store(in: &userProvider.disposeBag)
//    }
}
