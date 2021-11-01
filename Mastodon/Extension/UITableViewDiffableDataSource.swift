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
        if #available(iOS 15.0, *) {
            self.applySnapshotUsingReloadData(snapshot, completion: completion)
        } else {
            self.apply(snapshot, animatingDifferences: false, completion: completion)
        }
    }
    
    func applySnapshot(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animated: Bool,
        completion: (() -> Void)? = nil) {
            
            if #available(iOS 15.0, *) {
                self.apply(snapshot, animatingDifferences: animated, completion: completion)
            } else {
                if animated {
                    self.apply(snapshot, animatingDifferences: true, completion: completion)
                } else {
                    UIView.performWithoutAnimation {
                        self.apply(snapshot, animatingDifferences: true, completion: completion)
                    }
                }
            }
        }
}
