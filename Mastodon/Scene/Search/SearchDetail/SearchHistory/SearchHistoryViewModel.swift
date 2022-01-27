//
//  SearchHistoryViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import Combine
import CoreDataStack
import CommonOSLog

final class SearchHistoryViewModel {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let searchHistoryFetchedResultController: SearchHistoryFetchedResultController

    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem>?

    init(context: AppContext) {
        self.context = context
        self.searchHistoryFetchedResultController = SearchHistoryFetchedResultController(managedObjectContext: context.managedObjectContext)

        context.authenticationService.activeMastodonAuthenticationBox
            .receive(on: DispatchQueue.main)
            .sink { [weak self] box in
                guard let self = self else { return }
                self.searchHistoryFetchedResultController.domain.value = box?.domain
                self.searchHistoryFetchedResultController.userID.value = box?.userID
            }
            .store(in: &disposeBag)
    }

}

//extension SearchHistoryViewModel {
//    func persistSearchHistory(for item: SearchHistoryItem) {
//        guard let box = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
//        let property = SearchHistory.Property(domain: box.domain, userID: box.userID)
//
//        switch item {
//        case .account(let objectID):
//            let managedObjectContext = context.backgroundManagedObjectContext
//            managedObjectContext.performChanges {
//                guard let user = try? managedObjectContext.existingObject(with: objectID) as? MastodonUser else { return }
//                if let searchHistory = user.findSearchHistory(domain: box.domain, userID: box.userID) {
//                    searchHistory.update(updatedAt: Date())
//                } else {
//                    SearchHistory.insert(into: managedObjectContext, property: property, account: user)
//                }
//            }
//            .sink { result in
//                switch result {
//                case .failure(let error):
//                    assertionFailure(error.localizedDescription)
//                case .success:
//                    break
//                }
//            }
//            .store(in: &context.disposeBag)
//
//        case .hashtag(let objectID):
//            let managedObjectContext = context.backgroundManagedObjectContext
//            managedObjectContext.performChanges {
//                guard let hashtag = try? managedObjectContext.existingObject(with: objectID) as? Tag else { return }
//                if let searchHistory = hashtag.findSearchHistory(domain: box.domain, userID: box.userID) {
//                    searchHistory.update(updatedAt: Date())
//                } else {
//                    _ = SearchHistory.insert(into: managedObjectContext, property: property, hashtag: hashtag)
//                }
//            }
//            .sink { result in
//                switch result {
//                case .failure(let error):
//                    assertionFailure(error.localizedDescription)
//                case .success:
//                    break
//                }
//            }
//            .store(in: &context.disposeBag)
//
//        case .status:
//            // FIXME:
//            break
//        }
//    }
//
//    func clearSearchHistory() {
//        let managedObjectContext = context.backgroundManagedObjectContext
//        managedObjectContext.performChanges {
//            let request = SearchHistory.sortedFetchRequest
//            let searchHistories = managedObjectContext.safeFetch(request)
//            for searchHistory in searchHistories {
//                managedObjectContext.delete(searchHistory)
//            }
//        }
//        .sink { result in
//            // do nothing
//        }
//        .store(in: &context.disposeBag)
//    }
//}
