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
import MastodonCore

final class SearchHistoryViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let searchHistoryFetchedResultController: SearchHistoryFetchedResultController

    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem>?

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.searchHistoryFetchedResultController = SearchHistoryFetchedResultController(managedObjectContext: context.managedObjectContext)

        searchHistoryFetchedResultController.domain.value = authContext.mastodonAuthenticationBox.domain
        searchHistoryFetchedResultController.userID.value = authContext.mastodonAuthenticationBox.userID
    }

}
