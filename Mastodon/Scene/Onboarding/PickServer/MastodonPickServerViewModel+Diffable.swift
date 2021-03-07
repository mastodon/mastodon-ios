//
//  MastodonPickServerViewController+Diffable.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import UIKit

extension MastodonPickServerViewModel {
    
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        pickServerCategoriesCellDelegate: PickServerCategoriesCellDelegate,
        pickServerSearchCellDelegate: PickServerSearchCellDelegate,
        pickServerCellDelegate: PickServerCellDelegate
    ) {
        diffableDataSource = PickServerSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            pickServerCategoriesCellDelegate: pickServerCategoriesCellDelegate,
            pickServerSearchCellDelegate: pickServerSearchCellDelegate,
            pickServerCellDelegate: pickServerCellDelegate
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<PickServerSection, PickServerItem>()
        snapshot.appendSections([.header, .category, .search, .servers])
        snapshot.appendItems([.header], toSection: .header)
        snapshot.appendItems([.categoryPicker(items: categoryPickerItems)], toSection: .category)
        snapshot.appendItems([.search], toSection: .search)
        diffableDataSource?.apply(snapshot, animatingDifferences: false, completion: nil)
        
        loadIndexedServerStateMachine.enter(LoadIndexedServerState.Loading.self)
    }
    
}


