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
    let userFetchedResultsController: UserFetchedResultsController

    @Published var familiarFollowers: Mastodon.Entity.FamiliarFollowers?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>?
    
    init(context: AppContext) {
        self.context = context
        self.userFetchedResultsController = UserFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: nil,
            additionalPredicate: nil
        )
        // end init
        
        context.authenticationService.activeMastodonAuthenticationBox
            .map { $0?.domain }
            .assign(to: \.domain, on: userFetchedResultsController)
            .store(in: &disposeBag)
        
        $familiarFollowers
            .map { familiarFollowers -> [MastodonUser.ID] in
                guard let familiarFollowers = familiarFollowers else { return [] }
                return familiarFollowers.accounts.map { $0.id }
            }
            .assign(to: \.userIDs, on: userFetchedResultsController)
            .store(in: &disposeBag)
    }
    
}
