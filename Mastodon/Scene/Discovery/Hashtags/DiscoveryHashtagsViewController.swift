//
//  DiscoveryHashtagsViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import os.log
import UIKit
import Combine
import MastodonCore
import MastodonUI

final class DiscoveryHashtagsViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "TrendPostsViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: DiscoveryHashtagsViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    let refreshControl = RefreshControl()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension DiscoveryHashtagsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(DiscoveryHashtagsViewController.refreshControlValueChanged(_:)), for: .valueChanged)

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppeared.send()
    }
    
}

extension DiscoveryHashtagsViewController {
    
    @objc private func refreshControlValueChanged(_ sender: RefreshControl) {
        Task { @MainActor in
            do {
                try await viewModel.fetch()
            } catch {
                // do nothing
            }
            sender.endRefreshing()
        }   // end Task
    }
    
}

// MARK: - UITableViewDelegate
extension DiscoveryHashtagsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(indexPath)")
        guard case let .hashtag(tag) = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else { return }
        let hashtagTimelineViewModel = HashtagTimelineViewModel(context: context, authContext: viewModel.authContext, hashtag: tag.name)
        _ = coordinator.present(
            scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
            from: self,
            transition: .show
        )
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TrendTableViewCell else { return }
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        if let lastItem = diffableDataSource.snapshot().itemIdentifiers.last, item == lastItem {
            cell.configureSeparator(style: .edge)
        }
    }
}

// MARK: ScrollViewContainer
extension DiscoveryHashtagsViewController: ScrollViewContainer {
    var scrollView: UIScrollView { tableView }
}

extension DiscoveryHashtagsViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands
    }
}

// MARK: - TableViewControllerNavigateable
extension DiscoveryHashtagsViewController: TableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }
    
    func navigate(direction: TableViewNavigationDirection) {
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            // navigate up/down on the current selected item
            navigateToTag(direction: direction, indexPath: indexPathForSelectedRow)
        } else {
            // set first visible item selected
            navigateToFirstVisibleTag()
        }
    }
    
    private func navigateToTag(direction: TableViewNavigationDirection, indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let items = diffableDataSource.snapshot().itemIdentifiers
        guard let selectedItem = diffableDataSource.itemIdentifier(for: indexPath),
              let selectedItemIndex = items.firstIndex(of: selectedItem) else {
            return
        }

        let _navigateToItem: DiscoveryItem? = {
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
    
    private func navigateToFirstVisibleTag() {
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return }
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        
        var visibleItems: [DiscoveryItem] = indexPathsForVisibleRows.sorted().compactMap { indexPath in
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
    
    static func validNavigateableItem(_ item: DiscoveryItem) -> Bool {
        switch item {
        case .hashtag:
            return true
        default:
            return false
        }
    }
    
    func open() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPathForSelectedRow) else { return }
        
        guard case let .hashtag(tag) = item else { return }
        let hashtagTimelineViewModel = HashtagTimelineViewModel(context: context, authContext: viewModel.authContext, hashtag: tag.name)
        _ = coordinator.present(
            scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
            from: self,
            transition: .show
        )
    }
}
