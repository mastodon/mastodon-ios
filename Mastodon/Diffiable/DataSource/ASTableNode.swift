//
//  ASTableNode.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-19.
//

#if ASDK

import UIKit
import AsyncDisplayKit
import DifferenceKit
import DiffableDataSources

extension ASTableNode: ReloadableTableView {
    public func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        deleteSectionsAnimation: @autoclosure () -> UITableView.RowAnimation,
        insertSectionsAnimation: @autoclosure () -> UITableView.RowAnimation,
        reloadSectionsAnimation: @autoclosure () -> UITableView.RowAnimation,
        deleteRowsAnimation: @autoclosure () -> UITableView.RowAnimation,
        insertRowsAnimation: @autoclosure () -> UITableView.RowAnimation,
        reloadRowsAnimation: @autoclosure () -> UITableView.RowAnimation,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void
    ) {
        if case .none = view.window, let data = stagedChangeset.last?.data {
            setData(data)
            return reloadData()
        }

        for changeset in stagedChangeset {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData(data)
                return reloadData()
            }

            func updates() {
                setData(changeset.data)

                if !changeset.sectionDeleted.isEmpty {
                    deleteSections(IndexSet(changeset.sectionDeleted), with: deleteSectionsAnimation())
                }

                if !changeset.sectionInserted.isEmpty {
                    insertSections(IndexSet(changeset.sectionInserted), with: insertSectionsAnimation())
                }

                if !changeset.sectionUpdated.isEmpty {
                    reloadSections(IndexSet(changeset.sectionUpdated), with: reloadSectionsAnimation())
                }

                for (source, target) in changeset.sectionMoved {
                    moveSection(source, toSection: target)
                }

                if !changeset.elementDeleted.isEmpty {
                    deleteRows(at: changeset.elementDeleted.map { IndexPath(row: $0.element, section: $0.section) }, with: deleteRowsAnimation())
                }

                if !changeset.elementInserted.isEmpty {
                    insertRows(at: changeset.elementInserted.map { IndexPath(row: $0.element, section: $0.section) }, with: insertRowsAnimation())
                }

                if !changeset.elementUpdated.isEmpty {
                    reloadRows(at: changeset.elementUpdated.map { IndexPath(row: $0.element, section: $0.section) }, with: reloadRowsAnimation())
                }

                for (source, target) in changeset.elementMoved {
                    moveRow(at: IndexPath(row: source.element, section: source.section), to: IndexPath(row: target.element, section: target.section))
                }
            }

            if isNodeLoaded {
                view.beginUpdates()
                updates()
                view.endUpdates(animated: false, completion: nil)
            } else {
                updates()
            }
        }
    }
}

#endif
