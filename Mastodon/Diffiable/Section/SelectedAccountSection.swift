//
//  SelectedAccountSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/22.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit

enum SelectedAccountSection: Equatable, Hashable {
    case main
}

extension SelectedAccountSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        managedObjectContext: NSManagedObjectContext
    ) -> UICollectionViewDiffableDataSource<SelectedAccountSection, SelectedAccountItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SuggestionAccountCollectionViewCell.self), for: indexPath) as! SuggestionAccountCollectionViewCell
            switch item {
            case .accountObjectID(let objectID):
                let user = managedObjectContext.object(with: objectID) as! MastodonUser
                cell.config(with: user)
            case .placeHolder:
                cell.configAsPlaceHolder()
            }
            return cell
        }
    }
}
