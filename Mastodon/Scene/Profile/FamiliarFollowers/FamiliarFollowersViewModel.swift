//
//  FamiliarFollowersViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import Combine
import MastodonCore
import MastodonSDK
import CoreDataStack

final class FamiliarFollowersViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
//    let userFetchedResultsController: UserFetchedResultsController
    @Published var records = [Mastodon.Entity.Account]()
    @Published var familiarFollowers: Mastodon.Entity.FamiliarFollowers?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>?

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
//        self.userFetchedResultsController = UserFetchedResultsController(
//            managedObjectContext: context.managedObjectContext,
//            domain: authContext.mastodonAuthenticationBox.domain,
//            additionalPredicate: nil
//        )
        // end init
        
        $familiarFollowers
            .map { familiarFollowers in
                guard let familiarFollowers = familiarFollowers else { return [] }
                return familiarFollowers.accounts
            }
            .assign(to: \.records, on: self)
            .store(in: &disposeBag)
    }
    
}
