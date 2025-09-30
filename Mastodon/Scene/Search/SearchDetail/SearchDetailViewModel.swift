//
//  SearchDetailViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import Foundation
import CoreGraphics
import Combine
import MastodonSDK
import MastodonCore
import MastodonAsset
import MastodonLocalization

final class SearchDetailViewModel {
    
    // input
    let authenticationBox: MastodonAuthenticationBox
    var needsBecomeFirstResponder = false
    let viewDidAppear = PassthroughSubject<Void, Never>()
    let navigationBarFrame = CurrentValueSubject<CGRect, Never>(.zero)
    
    // output
    let searchScopes = SearchScope.allCases
    let selectedSearchScope = CurrentValueSubject<SearchScope, Never>(.all)
    let searchText: CurrentValueSubject<String, Never>
    let searchActionPublisher = PassthroughSubject<Void, Never>()
    
    init(authenticationBox: MastodonAuthenticationBox, initialSearchText: String = "") {
        self.authenticationBox = authenticationBox
        self.searchText = CurrentValueSubject(initialSearchText)
    }
}

public enum SearchScope: CaseIterable {
    case all
    case people
    case hashtags
    case posts
    
    var searchType: Mastodon.API.V2.Search.SearchType {
        switch self {
            case .all:          return .default
            case .people:       return .accounts
            case .hashtags:     return .hashtags
            case .posts:        return .statuses
        }
    }
}
