//
//  SearchHistorySection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import MastodonCore
import MastodonAsset
import MastodonSDK

enum SearchHistorySection: Hashable {
    case main
}

extension SearchHistorySection {
    
    struct Configuration {
        weak var searchHistorySectionHeaderCollectionReusableViewDelegate: SearchHistorySectionHeaderCollectionReusableViewDelegate?
    }
    
    static func diffableDataSource(
        viewModel: SearchHistoryViewModel,
        collectionView: UICollectionView,
        authContext: AuthContext,
        context: AppContext,
        configuration: Configuration
    ) -> UICollectionViewDiffableDataSource<SearchHistorySection, SearchHistoryItem> {
        
        let userCellRegister = UICollectionView.CellRegistration<SearchHistoryUserCollectionViewCell, Mastodon.Entity.Account> { cell, indexPath, item in
            context.managedObjectContext.performAndWait {
                cell.condensedUserView.configure(with: item)
            }
        }
        
        let hashtagCellRegister = UICollectionView.CellRegistration<UICollectionViewListCell, Mastodon.Entity.Tag> { cell, indexPath, item in
            context.managedObjectContext.performAndWait {
                var contentConfiguration = cell.defaultContentConfiguration()
                contentConfiguration.image = UIImage(systemName: "magnifyingglass")
                contentConfiguration.imageProperties.tintColor = Asset.Colors.Brand.blurple.color
                contentConfiguration.text = "#" + item.name
                cell.contentConfiguration = contentConfiguration
            }
            
            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColorTransformer = .init { [weak cell] _ in
                guard let state = cell?.configurationState else {
                    return .secondarySystemGroupedBackground
                }
                
                if state.isHighlighted || state.isSelected {
                    return SystemTheme.tableViewCellSelectionBackgroundColor
                }
                return .secondarySystemGroupedBackground
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
        
        let trendHeaderRegister = UICollectionView.SupplementaryRegistration<SearchHistorySectionHeaderCollectionReusableView>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            supplementaryView.delegate = configuration.searchHistorySectionHeaderCollectionReusableViewDelegate
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
