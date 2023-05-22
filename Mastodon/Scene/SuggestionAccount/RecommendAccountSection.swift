//
//  RecommendAccountSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import MetaTextKit
import MastodonMeta
import Combine
import MastodonCore

enum RecommendAccountSection: Equatable, Hashable {
    case main
}

extension RecommendAccountSection {
    
    struct Configuration {
        let authContext: AuthContext
        weak var suggestionAccountTableViewCellDelegate: SuggestionAccountTableViewCellDelegate?
    }

    static func tableViewDiffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<RecommendAccountSection, RecommendAccountItem> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SuggestionAccountTableViewCell.self)) as! SuggestionAccountTableViewCell
            switch item {
            case .account(let record):
                cell.delegate = configuration.suggestionAccountTableViewCellDelegate
                context.managedObjectContext.performAndWait {
                    guard let user = record.object(in: context.managedObjectContext) else { return }
                    cell.configure(viewModel:
                                    SuggestionAccountTableViewCell.ViewModel(
                                        user: user,
                                        followedUsers: configuration.authContext.mastodonAuthenticationBox.inMemoryCache.followingUserIds,
                                        blockedUsers: configuration.authContext.mastodonAuthenticationBox.inMemoryCache.blockedUserIds,
                                        followRequestedUsers: configuration.authContext.mastodonAuthenticationBox.inMemoryCache.followRequestedUserIDs)
                    )
                }
            }
            return cell
        }
    }
    
}
