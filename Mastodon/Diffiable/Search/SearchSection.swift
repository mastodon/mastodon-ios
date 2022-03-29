//
//  SearchSection.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import UIKit
import MastodonSDK
import MastodonLocalization

enum SearchSection: Hashable {
    case trend
}

extension SearchSection {
    
    static func diffableDataSource(
        collectionView: UICollectionView,
        context: AppContext
    ) -> UICollectionViewDiffableDataSource<SearchSection, SearchItem> {
        
        let trendCellRegister = UICollectionView.CellRegistration<TrendCollectionViewCell, Mastodon.Entity.Tag> { cell, indexPath, item in
            let primaryLabelText = "#" + item.name
            let secondaryLabelText = L10n.Scene.Search.Recommend.HashTag.peopleTalking(item.talkingPeopleCount ?? 0)
            
            cell.primaryLabel.text = primaryLabelText
            cell.secondaryLabel.text = secondaryLabelText
            
            cell.lineChartView.data = (item.history ?? [])
                .sorted(by: { $0.day < $1.day })        // latest last
                .map { entry in
                    guard let point = Int(entry.accounts) else {
                        return .zero
                    }
                    return CGFloat(point)
                }
            
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = [
                primaryLabelText,
                secondaryLabelText
            ].joined(separator: ", ")
        }
        
        let dataSource = UICollectionViewDiffableDataSource<SearchSection, SearchItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .trend(let hashtag):
                let cell = collectionView.dequeueConfiguredReusableCell(
                    using: trendCellRegister,
                    for: indexPath,
                    item: hashtag
                )
                return cell
            }
        }
        
        let trendHeaderRegister = UICollectionView.SupplementaryRegistration<TrendSectionHeaderCollectionReusableView>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            // do nothing
        }
        
        dataSource.supplementaryViewProvider = { [weak dataSource] (collectionView: UICollectionView, elementKind: String, indexPath: IndexPath) in
            let fallback = UICollectionReusableView()
            guard let dataSource = dataSource else { return fallback }
            let sections = dataSource.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return fallback }
            let section = sections[indexPath.section]
            
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                switch section {
                case .trend:
                    return collectionView.dequeueConfiguredReusableSupplementary(using: trendHeaderRegister, for: indexPath)
                }
            default:
                assertionFailure()
                return fallback
            }
        }
        
        return dataSource
    }   // end func
}
