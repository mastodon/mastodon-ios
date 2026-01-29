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
import MastodonCore
import MastodonSDK
import OSLog
import UIKit

final class SearchViewModel: NSObject {
    // input
    let authenticationBox: MastodonAuthenticationBox?
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var hashtags: [Mastodon.Entity.Tag] = []
    
    init(authenticationBox: MastodonAuthenticationBox?) {
        self.authenticationBox = authenticationBox
        super.init()
    }
}
