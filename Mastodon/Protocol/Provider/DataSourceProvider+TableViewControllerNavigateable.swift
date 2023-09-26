//
//  DataSourceProvider+TableViewControllerNavigateable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-16.
//

import UIKit
import MastodonCore

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
        
        switch navigation {
        case .up:                   navigate(direction: .up)
        case .down:                 navigate(direction: .down)
        case .back:                 back()
        case .open:                 open()
        }
    }
    
}


// navigate status up/down
extension TableViewControllerNavigateableCore where Self: DataSourceProvider {

    func navigate(direction: TableViewNavigationDirection) {
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            // navigate up/down on the current selected item
            Task {
                await navigateToStatus(direction: direction, indexPath: indexPathForSelectedRow)
            }
        } else {
            // set first visible item selected
            navigateToFirstVisibleStatus()
        }
    }
    
    @MainActor
    private func navigateToStatus(
        direction: TableViewNavigationDirection,
        indexPath: IndexPath
    ) async {
        let row: Int = {
            let index = indexPath.row
            switch direction {
            case .up:   return index - 1
            case .down: return index + 1
            }
        }()
        let indexPath = IndexPath(row: row , section: indexPath.section)
        guard indexPath.section >= 0, indexPath.section < tableView.numberOfSections,
              indexPath.row >= 0, indexPath.row < tableView.numberOfRows(inSection: indexPath.section)
        else { return }
        
        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
    }
    
    private func navigateToFirstVisibleStatus() {
        guard var indexPathsForVisibleRows = tableView.indexPathsForVisibleRows?.sorted() else { return }
        
        if indexPathsForVisibleRows.first?.row != 0 {
            // drop first when visible not the first cell of table
            indexPathsForVisibleRows.removeFirst()
        }
    
        guard let indexPath = indexPathsForVisibleRows.first else { return }
        let scrollPosition: UITableView.ScrollPosition = overrideNavigationScrollPosition ?? Self.navigateScrollPosition(tableView: tableView, indexPath: indexPath)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
    }
    
    static func validNavigateableItem(_ item: DataSourceItem) -> Bool {
        switch item {
        case .status,
             .notification:
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

extension TableViewControllerNavigateableCore where Self: DataSourceProvider & AuthContextProvider {
    func open() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        let source = DataSourceItem.Source(indexPath: indexPathForSelectedRow)
    
        Task { @MainActor in
            guard let item = await item(from: source) else { return }
            switch item {
            case .status(let record):
                await DataSourceFacade.coordinateToStatusThreadScene(
                    provider: self,
                    target: .status,
                    status: record
                )
            case .notification:
                assertionFailure()
            default:
                assertionFailure()
            }
        }   // end Task
//        StatusProviderFacade.coordinateToStatusThreadScene(for: .primary, provider: self, indexPath: indexPathForSelectedRow)
    }
}

extension TableViewControllerNavigateableCore where Self: UIViewController {
    func back() {
        UserDefaults.shared.backKeyCommandPressDate = Date()
        navigationController?.popViewController(animated: true)
    }
}
