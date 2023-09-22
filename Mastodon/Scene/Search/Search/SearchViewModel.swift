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
    }
}
