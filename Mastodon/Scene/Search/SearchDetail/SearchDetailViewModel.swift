//
//  SearchDetailViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import os.log
import Foundation
import CoreGraphics
import Combine
import MastodonSDK
import MastodonCore
import MastodonAsset
import MastodonLocalization

final class SearchDetailViewModel {

    // input
    let authContext: AuthContext
    var needsBecomeFirstResponder = false
    let viewDidAppear = PassthroughSubject<Void, Never>()
    let navigationBarFrame = CurrentValueSubject<CGRect, Never>(.zero)

    // output
    let searchScopes = SearchScope.allCases
    let selectedSearchScope = CurrentValueSubject<SearchScope, Never>(.all)
    let searchText: CurrentValueSubject<String, Never>
    let searchActionPublisher = PassthroughSubject<Void, Never>()

    init(authContext: AuthContext, initialSearchText: String = "") {
        self.authContext = authContext
        self.searchText = CurrentValueSubject(initialSearchText)
    }

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension SearchDetailViewModel {
    enum SearchScope: CaseIterable {
        case all
        case people
        case hashtags
        case posts

        var segmentedControlTitle: String {
            switch self {
            case .all:      return L10n.Scene.Search.Searching.Segment.all
            case .people:   return L10n.Scene.Search.Searching.Segment.people
            case .hashtags:  return L10n.Scene.Search.Searching.Segment.hashtags
            case .posts:     return L10n.Scene.Search.Searching.Segment.posts
            }
        }

        var searchType: Mastodon.API.V2.Search.SearchType {
            switch self {
            case .all:          return .default
            case .people:       return .accounts
            case .hashtags:     return .hashtags
            case .posts:        return .statuses
            }
        }
    }
}
