//
//  SuggestionAccountViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import os.log
import UIKit
    
final class SuggestionAccountViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let accounts = CurrentValueSubject<[NSManagedObjectID], Never>([])
    var selectedAccounts = [NSManagedObjectID]()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID>?
    
    init(context: AppContext, accounts: [NSManagedObjectID]? = nil) {
        self.context = context
        if let accounts = accounts {
            self.accounts.value = accounts
        }
        super.init()
        
        self.accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                guard let dataSource = self?.diffableDataSource else { return }
                var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, NSManagedObjectID>()
                snapshot.appendSections([.main])
                snapshot.appendItems(accounts, toSection: .main)
                dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
            }
            .store(in: &disposeBag)
        
        if accounts == nil || (accounts ?? []).isEmpty {
            guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }

            context.apiService.suggestionAccountV2(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch recommendAccountV2 failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                    case .finished:
                        // handle isFetchingLatestTimeline in fetch controller delegate
                        break
                    }
                } receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    let ids = response.value.map(\.account.id)
                    let users: [MastodonUser]? = {
                        let request = MastodonUser.sortedFetchRequest
                        request.predicate = MastodonUser.predicate(domain: activeMastodonAuthenticationBox.domain, ids: ids)
                        request.returnsObjectsAsFaults = false
                        do {
                            return try context.managedObjectContext.fetch(request)
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return nil
                        }
                    }()
                    if let accounts = users?.map(\.objectID) {
                        self.accounts.value = accounts
                    }
                }
                .store(in: &disposeBag)
        }
    }
    
    func followAction() {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        for objectID in selectedAccounts {
            let mastodonUser = context.managedObjectContext.object(with: objectID) as! MastodonUser
            context.apiService.toggleFollow(
                for: mastodonUser,
                activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
                needFeedback: false
            )
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: follow failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                case .finished:
                    // handle isFetchingLatestTimeline in fetch controller delegate
                    break
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
        }
    }
}
