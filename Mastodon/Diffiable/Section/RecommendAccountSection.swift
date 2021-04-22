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

enum RecommendAccountSection: Equatable, Hashable {
    case main
}

extension RecommendAccountSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        delegate: SearchRecommendAccountsCollectionViewCellDelegate,
        managedObjectContext: NSManagedObjectContext
    ) -> UICollectionViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak delegate] collectionView, indexPath, objectID -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchRecommendAccountsCollectionViewCell.self), for: indexPath) as! SearchRecommendAccountsCollectionViewCell
            let user = managedObjectContext.object(with: objectID) as! MastodonUser
            cell.delegate = delegate
            cell.config(with: user)
            return cell
        }
    }
    
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        managedObjectContext: NSManagedObjectContext,
        viewModel: SuggestionAccountViewModel,
        delegate: SuggestionAccountTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak viewModel, weak delegate] (tableView, indexPath, objectID) -> UITableViewCell? in
            guard let viewModel = viewModel else { return nil }
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SuggestionAccountTableViewCell.self)) as! SuggestionAccountTableViewCell
            let user = managedObjectContext.object(with: objectID) as! MastodonUser
            let isSelected = viewModel.selectedAccounts.contains(objectID)
            cell.delegate = delegate
            cell.config(with: user, isSelected: isSelected)
            return cell
        }
    }
}
