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
    
protocol SuggestionAccountViewModelDelegate: AnyObject {
    var homeTimelineNeedRefresh: PassthroughSubject<Void, Never> { get }
}
final class SuggestionAccountViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    weak var delegate: SuggestionAccountViewModelDelegate?
    // output
    let accounts = CurrentValueSubject<[NSManagedObjectID], Never>([])
    var selectedAccounts = [NSManagedObjectID]()
    var suggestionAccountsFallback = PassthroughSubject<Void, Never>()
    
    var diffableDataSource: UITableViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID>? {
        didSet(value) {
            if !accounts.value.isEmpty {
                applyDataSource(accounts: accounts.value)
            }
        }
    }
    
    init(context: AppContext, accounts: [NSManagedObjectID]? = nil) {
        self.context = context

        super.init()
        
        self.accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                self?.applyDataSource(accounts: accounts)
            }
            .store(in: &disposeBag)
        
        if let accounts = accounts {
            self.accounts.value = accounts
        }
        
        if accounts == nil || (accounts ?? []).isEmpty {
            guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }

            context.apiService.suggestionAccountV2(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        if let apiError = error as? Mastodon.API.Error {
                            if apiError.httpResponseStatus == .notFound {
                                self?.suggestionAccountsFallback.send()
                            }
                        }
                        os_log("%{public}s[%{public}ld], %{public}s: fetch recommendAccountV2 failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                    case .finished:
                        // handle isFetchingLatestTimeline in fetch controller delegate
                        break
                    }
                } receiveValue: { [weak self] response in
                    let ids = response.value.map(\.account.id)
                    self?.receiveAccounts(ids: ids)
                }
                .store(in: &disposeBag)
            
            suggestionAccountsFallback
                .sink(receiveValue: { [weak self] _ in
                    self?.requestSuggestionAccount()
                })
                .store(in: &disposeBag)
        }
    }
    
    func requestSuggestionAccount() {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        context.apiService.suggestionAccount(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: fetch recommendAccount failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                case .finished:
                    // handle isFetchingLatestTimeline in fetch controller delegate
                    break
                }
            } receiveValue: { [weak self] response in
                let ids = response.value.map(\.id)
                self?.receiveAccounts(ids: ids)
            }
            .store(in: &disposeBag)
    }
    
    func applyDataSource(accounts: [NSManagedObjectID]) {
        guard let dataSource = diffableDataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, NSManagedObjectID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(accounts, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }

    func receiveAccounts(ids: [String]) {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
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
                    self.delegate?.homeTimelineNeedRefresh.send()
                    break
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
        }
    }
}
