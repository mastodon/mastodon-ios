//
//  SearchHistorySection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import CoreDataStack
import MastodonCore

enum SearchHistorySection: Hashable {
    case main
}

extension SearchHistorySection {
    
    struct Configuration {
        weak var searchHistorySectionHeaderCollectionReusableViewDelegate: SearchHistorySectionHeaderCollectionReusableViewDelegate?
    }
    
    static func diffableDataSource(
        collectionView: UICollectionView,
        context: AppContext,
        configuration: Configuration
    ) -> UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem> {
        
        let userCellRegister = UICollectionView.CellRegistration<SearchHistoryUserCollectionViewCell, ManagedObjectRecord<MastodonUser>> { cell, indexPath, item in
            context.managedObjectContext.performAndWait {
                guard let user = item.object(in: context.managedObjectContext) else { return }
                cell.configure(viewModel: .init(value: user))
            }
        }
        
        let hashtagCellRegister = UICollectionView.CellRegistration<UICollectionViewListCell, ManagedObjectRecord<Tag>> { cell, indexPath, item in
            context.managedObjectContext.performAndWait {
                guard let hashtag = item.object(in: context.managedObjectContext) else { return }
                var contentConfiguration = cell.defaultContentConfiguration()
                contentConfiguration.text = "#" + hashtag.name
                cell.contentConfiguration = contentConfiguration
            }
            
            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColorTransformer = .init { [weak cell] _ in
                guard let state = cell?.configurationState else {
                    return ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
                }
                
                if state.isHighlighted || state.isSelected {
                    return ThemeService.shared.currentTheme.value.tableViewCellSelectionBackgroundColor
                }
                return ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
            }
            cell.backgroundConfiguration = backgroundConfiguration
        }
        
        let dataSource = UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .user(let record):
                return collectionView.dequeueConfiguredReusableCell(
                    using: userCellRegister,
                    for: indexPath, item: record)
            case .hashtag(let record):
                return collectionView.dequeueConfiguredReusableCell(
                    using: hashtagCellRegister,
                    for: indexPath, item: record)
            }
        }
        
        let trendHeaderRegister = UICollectionView.SupplementaryRegistration<SearchHistorySectionHeaderCollectionReusableView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak dataSource] supplementaryView, elementKind, indexPath in
            supplementaryView.delegate = configuration.searchHistorySectionHeaderCollectionReusableViewDelegate

            guard let _ = dataSource else { return }
            // let sections = dataSource.snapshot().sectionIdentifiers
            // guard indexPath.section < sections.count else { return }
            // let section = sections[indexPath.section]
        }
        
        dataSource.supplementaryViewProvider = { (collectionView: UICollectionView, elementKind: String, indexPath: IndexPath) in
            let fallback = UICollectionReusableView()

            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: trendHeaderRegister, for: indexPath)
            default:
                assertionFailure()
                return fallback
            }
        }
        
        return dataSource
    }   // end func
}
