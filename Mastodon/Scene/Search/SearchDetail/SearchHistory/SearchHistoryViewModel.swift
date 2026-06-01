//
//  SearchHistoryViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import Combine
import MastodonCore

final class SearchHistoryViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let authenticationBox: MastodonAuthenticationBox
    @Published public var items: [Persistence.SearchHistory.Item]

    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem>?

    public var isRecentSearchEmpty: Bool {
        return items.isEmpty
    }
    
    init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
        self.items = (try? FileManager.default.searchItems(for: authenticationBox)) ?? []
    }

}
