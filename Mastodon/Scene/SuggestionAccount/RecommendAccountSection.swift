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
        let authenticationBox: MastodonAuthenticationBox
        weak var suggestionAccountTableViewCellDelegate: SuggestionAccountTableViewCellDelegate?
    }

    static func tableViewDiffableDataSource(
        tableView: UITableView,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<RecommendAccountSection, RecommendAccountItem> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SuggestionAccountTableViewCell.self)) as?
                    SuggestionAccountTableViewCell else {
                assertionFailure("unexpected cell dequeued")
                return nil
            }
            switch item {
                case .account(let account, let relationship):
                    cell.delegate = configuration.suggestionAccountTableViewCellDelegate
                    cell.configure(account: account, relationship: relationship)
            }
            return cell
        }
    }
}
