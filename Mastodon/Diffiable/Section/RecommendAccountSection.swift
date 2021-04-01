//
//  RecommendAccountSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Foundation
import MastodonSDK
import UIKit

enum RecommendAccountSection: Equatable, Hashable {
    case main
}

extension RecommendAccountSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView
    ) -> UICollectionViewDiffableDataSource<RecommendAccountSection, Mastodon.Entity.Account> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, account -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchRecommendAccountsCollectionViewCell.self), for: indexPath) as! SearchRecommendAccountsCollectionViewCell
            cell.config(with: account)
            return cell
        }
    }
}
