//
//  SelectedAccountSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/22.
//

import UIKit
import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK

enum SelectedAccountSection: Equatable, Hashable {
    case main
}

extension SelectedAccountSection {
    static func collectionViewDiffableDataSource(
        collectionView: UICollectionView,
        context: AppContext
    ) -> UICollectionViewDiffableDataSource<SelectedAccountSection, SelectedAccountItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SuggestionAccountCollectionViewCell.self), for: indexPath) as! SuggestionAccountCollectionViewCell
            switch item {
            case .account(let record):
                context.managedObjectContext.performAndWait {
                    guard let user = record.object(in: context.managedObjectContext) else { return }
                    cell.config(with: user)
                }
            case .placeHolder:
                cell.configAsPlaceHolder()
            }
            return cell
        }
    }
}
