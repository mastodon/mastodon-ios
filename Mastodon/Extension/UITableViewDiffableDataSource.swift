//
//  UITableViewDiffableDataSource.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-11.
//

import UIKit

// ref: https://www.jessesquires.com/blog/2021/07/08/diffable-data-source-behavior-changes-and-reconfiguring-cells-in-ios-15/
extension UITableViewDiffableDataSource {
    func reloadData(
        snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        completion: (() -> Void)? = nil
    ) {
        self.applySnapshotUsingReloadData(snapshot, completion: completion)
    }
    
    func applySnapshot(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animated: Bool,
        completion: (() -> Void)? = nil) {
            self.apply(snapshot, animatingDifferences: animated, completion: completion)
        }
}
