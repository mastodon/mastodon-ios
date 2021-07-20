//
//  SearchViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import GameplayKit
import MastodonSDK
import OSLog
import UIKit

final class SearchViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    weak var coordinator: SceneCoordinator!
    
    let currentMastodonUser = CurrentValueSubject<MastodonUser?, Never>(nil)
    let viewDidAppeared = PassthroughSubject<Void, Never>()
    
    // output

    // var recommendHashTags = [Mastodon.Entity.Tag]()
    var recommendAccounts = [NSManagedObjectID]()
    var recommendAccountsFallback = PassthroughSubject<Void, Never>()
    
    var hashtagDiffableDataSource: UICollectionViewDiffableDataSource<RecommendHashTagSection, Mastodon.Entity.Tag>?
    var accountDiffableDataSource: UICollectionViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID>?

    init(context: AppContext, coordinator: SceneCoordinator) {
        self.coordinator = coordinator
        self.context = context
        super.init()

        Publishers.CombineLatest(
            context.authenticationService.activeMastodonAuthenticationBox,
            viewDidAppeared
        )
        .compactMap { activeMastodonAuthenticationBox, _ -> MastodonAuthenticationBox? in
            return activeMastodonAuthenticationBox
        }
        .throttle(for: 1, scheduler: DispatchQueue.main, latest: false)
        .flatMap { box in
            context.apiService.recommendTrends(domain: box.domain, query: nil)
                .map { response in Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { response } }
                .catch { error in Just(Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { throw error }) }
                .eraseToAnyPublisher()
        }
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let dataSource = self.hashtagDiffableDataSource else { return }
                var snapshot = NSDiffableDataSourceSnapshot<RecommendHashTagSection, Mastodon.Entity.Tag>()
                snapshot.appendSections([.main])
                snapshot.appendItems(response.value, toSection: .main)
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
            case .failure(let error):
                break
            }
        }
        .store(in: &disposeBag)

        Publishers.CombineLatest(
            context.authenticationService.activeMastodonAuthenticationBox,
            viewDidAppeared
        )
        .compactMap { activeMastodonAuthenticationBox, _ -> MastodonAuthenticationBox? in
            return activeMastodonAuthenticationBox
        }
        .throttle(for: 1, scheduler: DispatchQueue.main, latest: false)
        .flatMap { box -> AnyPublisher<Result<[Mastodon.Entity.Account.ID], Error>, Never> in
            context.apiService.suggestionAccountV2(domain: box.domain, query: nil, mastodonAuthenticationBox: box)
                .map { response in Result<[Mastodon.Entity.Account.ID], Error> { response.value.map { $0.account.id } } }
                .catch { error -> AnyPublisher<Result<[Mastodon.Entity.Account.ID], Error>, Never> in
                    if let apiError = error as? Mastodon.API.Error, apiError.httpResponseStatus == .notFound {
                        return context.apiService.suggestionAccount(domain: box.domain, query: nil, mastodonAuthenticationBox: box)
                            .map { response in Result<[Mastodon.Entity.Account.ID], Error> { response.value.map { $0.id } } }
                            .catch { error in Just(Result<[Mastodon.Entity.Account.ID], Error> { throw error }) }
                            .eraseToAnyPublisher()
                    } else {
                        return Just(Result<[Mastodon.Entity.Account.ID], Error> { throw error })
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        }
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userIDs):
                self.receiveAccounts(ids: userIDs)
            case .failure(let error):
                break
            }
        }
        .store(in: &disposeBag)
    }
    
    func receiveAccounts(ids: [Mastodon.Entity.Account.ID]) {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let userFetchRequest = MastodonUser.sortedFetchRequest
        userFetchRequest.predicate = MastodonUser.predicate(domain: activeMastodonAuthenticationBox.domain, ids: ids)
        let mastodonUsers: [MastodonUser]? = {
            let userFetchRequest = MastodonUser.sortedFetchRequest
            userFetchRequest.predicate = MastodonUser.predicate(domain: activeMastodonAuthenticationBox.domain, ids: ids)
            userFetchRequest.returnsObjectsAsFaults = false
            do {
                return try self.context.managedObjectContext.fetch(userFetchRequest)
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        guard let users = mastodonUsers else { return }
        let objectIDs: [NSManagedObjectID] = users
            .compactMap { object in
                ids.firstIndex(of: object.id).map { index in (index, object) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }

        // append at front
        let newObjectIDs = objectIDs.filter { !self.recommendAccounts.contains($0) }
        self.recommendAccounts = newObjectIDs + self.recommendAccounts

        guard let dataSource = self.accountDiffableDataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, NSManagedObjectID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(self.recommendAccounts, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }

}
