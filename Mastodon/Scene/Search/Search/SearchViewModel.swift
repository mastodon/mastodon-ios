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
import MastodonCore
import MastodonSDK
import OSLog
import UIKit

final class SearchViewModel: NSObject {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext?
    let viewDidAppeared = PassthroughSubject<Void, Never>()
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var hashtags: [Mastodon.Entity.Tag] = []
    
    init(context: AppContext, authContext: AuthContext?) {
        self.context = context
        self.authContext = authContext
        super.init()
        
//        Publishers.CombineLatest(
//            context.authenticationService.activeMastodonAuthenticationBox,
//            viewDidAppeared
//        )
//        .compactMap { authenticationBox, _ -> MastodonAuthenticationBox? in
//            return authenticationBox
//        }
//        .throttle(for: 3, scheduler: DispatchQueue.main, latest: true)
//        .asyncMap { authenticationBox in
//            try await context.apiService.trendHashtags(domain: authenticationBox.domain, query: nil)
//        }
//        .retry(3)
//        .map { response in Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { response } }
//        .catch { error in Just(Result<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> { throw error }) }
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let response):
//                self.hashtags = response.value
//            case .failure:
//                break
//            }
//        }
//        .store(in: &disposeBag)
    }

}
