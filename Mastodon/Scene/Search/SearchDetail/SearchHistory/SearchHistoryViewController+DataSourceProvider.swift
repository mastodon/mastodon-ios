//
//  SearchHistoryViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit
import MastodonSDK

// MARK: - DataSourceProvider
extension SearchHistoryViewController {
    var filterContext: MastodonSDK.Mastodon.Entity.FilterContext? {
        return .none
    }
    
    func didToggleContentWarningDisplayStatus(status: MastodonSDK.MastodonStatus) {
        collectionView.reloadData()
    }
    
    func item(from source: LegacyDataSourceFacade.DataSourceItem.Source) async -> LegacyDataSourceFacade.DataSourceItem? {
        var _indexPath = source.indexPath
        if _indexPath == nil, let cell = source.collectionViewCell {
            _indexPath = await self.indexPath(for: cell)
        }
        guard let indexPath = _indexPath else { return nil }
        
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        switch item {
        case .account(let account):
            return .account(account: account, relationship: nil)
        case .hashtag(let tag):
            return .hashtag(tag: tag)
        }
    }
    
    func update(contentStatus: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        assertionFailure("Not required")
    }

    @MainActor
    private func indexPath(for cell: UICollectionViewCell) async -> IndexPath? {
        return collectionView.indexPath(for: cell)
    }
}

