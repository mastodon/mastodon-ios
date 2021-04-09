//
//  RecommendAccountSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Foundation
import MastodonSDK
import UIKit
import CoreData
import CoreDataStack

enum RecommendAccountSection: Equatable, Hashable {
    case main
}

extension RecommendAccountSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        context: AppContext!
    ) -> UICollectionViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, objectID -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchRecommendAccountsCollectionViewCell.self), for: indexPath) as! SearchRecommendAccountsCollectionViewCell
            let user = context.managedObjectContext.object(with: objectID) as! MastodonUser
            cell.config(with: user)
            if let currentUser = context.authenticationService.activeMastodonAuthentication.value?.user {
                cell.configFollowButton(with: user, currentMastodonUser: currentUser)
            }
            return cell
        }
    }
}
