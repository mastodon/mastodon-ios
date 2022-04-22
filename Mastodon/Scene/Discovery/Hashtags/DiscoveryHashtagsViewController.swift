//
//  DiscoveryHashtagsViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import os.log
import UIKit
import Combine
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
    
    let refreshControl = UIRefreshControl()
    
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
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
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
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
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
        let hashtagTimelineViewModel = HashtagTimelineViewModel(context: context, hashtag: tag.name)
        coordinator.present(
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
    var scrollView: UIScrollView? {
        tableView
    }
}
