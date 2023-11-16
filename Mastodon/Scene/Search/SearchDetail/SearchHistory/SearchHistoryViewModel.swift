//
//  SearchHistoryViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import Combine
import MastodonCore
import MastodonSDK

struct SearchHistoryQueryItem {
    
}

final class SearchHistoryViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    @Published var records = [SearchHistoryQueryItem]()
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem>?

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
    }

}
