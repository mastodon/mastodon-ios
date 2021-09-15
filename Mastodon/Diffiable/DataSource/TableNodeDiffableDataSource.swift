//
//  TableNodeDiffableDataSource.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-19.
//

#if ASDK

import UIKit
import AsyncDisplayKit
import DiffableDataSources

open class TableNodeDiffableDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: NSObject, ASTableDataSource {
    /// The type of closure providing the cell.
    public typealias CellProvider = (ASTableNode, IndexPath, ItemIdentifierType) -> ASCellNodeBlock?

    /// The default animation to updating the views.
    public var defaultRowAnimation: UITableView.RowAnimation = .automatic

    private weak var tableNode: ASTableNode?
    private let cellProvider: CellProvider
    private let core = DiffableDataSourceCore<SectionIdentifierType, ItemIdentifierType>()

    /// Creates a new data source.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance to be managed.
    ///   - cellProvider: A closure to dequeue the cell for rows.
    public init(tableNode: ASTableNode, cellProvider: @escaping CellProvider) {
        self.tableNode = tableNode
        self.cellProvider = cellProvider
        super.init()

        tableNode.delegate = self
    }

    /// Applies given snapshot to perform automatic diffing update.
    ///
    /// - Parameters:
    ///   - snapshot: A snapshot object to be applied to data model.
    ///   - animatingDifferences: A Boolean value indicating whether to update with
    ///                           diffing animation.
    ///   - completion: An optional completion block which is called when the complete
    ///                 performing updates.
    public func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        core.apply(snapshot, view: tableNode, animatingDifferences: animatingDifferences, completion: completion)
    }

    /// Returns a new snapshot object of current state.
    ///
    /// - Returns: A new snapshot object of current state.
    public func snapshot() -> DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        return core.snapshot()
    }

    /// Returns an item identifier for given index path.
    ///
    /// - Parameters:
    ///   - indexPath: An index path for the item identifier.
    ///
    /// - Returns: An item identifier for given index path.
    public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        return core.itemIdentifier(for: indexPath)
    }

    /// Returns an index path for given item identifier.
    ///
    /// - Parameters:
    ///   - itemIdentifier: An identifier of item.
    ///
    /// - Returns: An index path for given item identifier.
    public func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        return core.indexPath(for: itemIdentifier)
    }

    /// Returns the number of sections in the data source.
    ///
    /// - Parameters:
    ///   - tableNode: A table node instance managed by `self`.
    ///
    /// - Returns: The number of sections in the data source.
    public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return core.numberOfSections()
    }

    /// Returns the number of items in the specified section.
    ///
    /// - Parameters:
    ///   - tableNode: A table node instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: The number of items in the specified section.
    public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return core.numberOfItems(inSection: section)
    }

    /// Returns a cell for row at specified index path.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - indexPath: An index path for cell.
    ///
    /// - Returns: A cell for row at specified index path.
    open func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let itemIdentifier = core.unsafeItemIdentifier(for: indexPath)
        guard let block = cellProvider(tableNode, indexPath, itemIdentifier) else {
            fatalError("UITableView dataSource returned a nil cell for row at index path: \(indexPath), tableNode: \(tableNode), itemIdentifier: \(itemIdentifier)")
        }

        return block
    }
}

#endif
