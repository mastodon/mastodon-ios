//
//  RecomendHashTagSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Foundation
import MastodonSDK
import UIKit

enum RecomendHashTagSection: Equatable, Hashable {
    case main
}

extension RecomendHashTagSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView
    ) -> UICollectionViewDiffableDataSource<RecomendHashTagSection, Mastodon.Entity.Tag> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, tag -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchRecommendTagsCollectionViewCell.self), for: indexPath) as! SearchRecommendTagsCollectionViewCell
            cell.config(with: tag)
            return cell
        }
    }
}
