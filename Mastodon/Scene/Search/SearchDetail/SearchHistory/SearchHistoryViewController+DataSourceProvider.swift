//
//  SearchHistoryViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit

// MARK: - DataSourceProvider
extension SearchHistoryViewController: DataSourceProvider {
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        var _indexPath = source.indexPath
        if _indexPath == nil, let cell = source.collectionViewCell {
            _indexPath = await self.indexPath(for: cell)
        }
        guard let indexPath = _indexPath else { return nil }
        
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        switch item {
        case .user(let record):
            return .user(record: record)
        case .hashtag(let record):
            return .hashtag(tag: .record(record))
        }
    }
    
    @MainActor
    private func indexPath(for cell: UICollectionViewCell) async -> IndexPath? {
        return collectionView.indexPath(for: cell)
    }
}

