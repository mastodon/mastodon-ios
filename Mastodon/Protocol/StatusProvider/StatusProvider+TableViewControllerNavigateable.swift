//
//  StatusProvider+TableViewControllerNavigateable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-21.
//

import os.log
import UIKit

extension TableViewControllerNavigateableCore where Self: TableViewControllerNavigateableRelay {
    var navigationKeyCommands: [UIKeyCommand] {
        TableViewNavigation.allCases.map { navigation in
            UIKeyCommand(
                title: navigation.title,
                image: nil,
                action: #selector(Self.navigateKeyCommandHandlerRelay(_:)),
                input: navigation.input,
                modifierFlags: navigation.modifierFlags,
                propertyList: navigation.propertyList,
                alternates: [],
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            )
        }
    }
}

extension TableViewControllerNavigateableCore {
    
    func navigateKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let navigation = TableViewNavigation(rawValue: rawValue) else { return }
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, navigation.title)
        switch navigation {
        case .up:                   navigate(direction: .up)
        case .down:                 navigate(direction: .down)
        case .back:                 back()
        case .open:                 open()
        }
    }
    
}


// navigate status up/down
extension TableViewControllerNavigateableCore where Self: StatusProvider {

    func navigate(direction: TableViewNavigationDirection) {
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            // navigate up/down on the current selected item
            navigateToStatus(direction: direction, indexPath: indexPathForSelectedRow)
        } else {
            // set first visible item selected
            navigateToFirstVisibleStatus()
        }
    }
    
    private func navigateToStatus(direction: TableViewNavigationDirection, indexPath: IndexPath) {
        guard let diffableDataSource = tableViewDiffableDataSource else { return }
        let items = diffableDataSource.snapshot().itemIdentifiers
        guard let selectedItem = diffableDataSource.itemIdentifier(for: indexPath),
              let selectedItemIndex = items.firstIndex(of: selectedItem) else {
            return
        }

        let _navigateToItem: Item? = {
            var index = selectedItemIndex
            while 0..<items.count ~= index {
                index = {
                    switch direction {
                    case .up:   return index - 1
                    case .down: return index + 1
                    }
                }()
                guard 0..<items.count ~= index else { return nil }
                let item = items[index]
                
                guard Self.validNavigateableItem(item) else { continue }
                return item
            }
            return nil
        }()
        
        guard let item = _navigateToItem, let indexPath = diffableDataSource.indexPath(for: item) else { return }
        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
    }
    
    private func navigateToFirstVisibleStatus() {
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return }
        guard let diffableDataSource = tableViewDiffableDataSource else { return }
        
        var visibleItems: [Item] = indexPathsForVisibleRows.sorted().compactMap { indexPath in
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
            guard Self.validNavigateableItem(item) else { return nil }
            return item
        }
        if indexPathsForVisibleRows.first?.row != 0, visibleItems.count > 1 {
            // drop first when visible not the first cell of table
            visibleItems.removeFirst()
        }
        guard let item = visibleItems.first, let indexPath = diffableDataSource.indexPath(for: item) else { return }
        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
    }
    
    static func validNavigateableItem(_ item: Item) -> Bool {
        switch item {
        case .homeTimelineIndex,
             .status,
             .root, .leaf, .reply:
            return true
        default:
            return false
        }
    }

}

extension TableViewControllerNavigateableCore {
    // check is visible and not the first and last
    static func navigateScrollPosition(tableView: UITableView, indexPath: IndexPath) -> UITableView.ScrollPosition {
        let middleVisibleIndexPaths = (tableView.indexPathsForVisibleRows ?? [])
            .sorted()
            .dropFirst()
            .dropLast()
        guard middleVisibleIndexPaths.contains(indexPath) else {
            return .top
        }
        guard middleVisibleIndexPaths.count > 2 else {
            return .middle
        }
        return .none
    }
    
}

extension TableViewControllerNavigateableCore where Self: StatusProvider {
    func open() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        StatusProviderFacade.coordinateToStatusThreadScene(for: .primary, provider: self, indexPath: indexPathForSelectedRow)
    }
}

extension TableViewControllerNavigateableCore where Self: UIViewController {
    func back() {
        UserDefaults.shared.backKeyCommandPressDate = Date()
        navigationController?.popViewController(animated: true)
    }
}
