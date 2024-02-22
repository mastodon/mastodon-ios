//
//  SearchHistoryViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import Combine
import CoreDataStack
import MastodonCore

final class SearchHistoryViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    @Published public var items: [Persistence.SearchHistory.Item]

    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem>?

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.items = (try? FileManager.default.searchItems(for: authContext.mastodonAuthenticationBox)) ?? []
    }

}
