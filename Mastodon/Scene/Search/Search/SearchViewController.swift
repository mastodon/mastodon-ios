//
//  SearchViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import os.log
import Combine
import GameplayKit
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonLocalization

final class HeightFixedSearchBar: UISearchBar {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)
    }
}

final class SearchViewController: UIViewController, NeedsDependency {

    let logger = Logger(subsystem: "SearchViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var searchTransitionController = SearchTransitionController()
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = SearchViewModel(context: context)
    
    // use AutoLayout could set search bar margin automatically to
    // layout alongside with split mode button (on iPad)
    let titleViewContainer = UIView()
    let searchBar = HeightFixedSearchBar()
    
    let collectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    let searchBarTapPublisher = PassthroughSubject<Void, Never>()
    
    private(set) lazy var trendViewController: DiscoveryViewController = {
        let viewController = DiscoveryViewController()
        viewController.context = context
        viewController.coordinator = coordinator
        return viewController
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension SearchViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        title = L10n.Scene.Search.title

        setupSearchBar()
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView
        )
        
        addChild(trendViewController)
        trendViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(trendViewController.view)
        NSLayoutConstraint.activate([
            trendViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            trendViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trendViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            trendViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppeared.send()
        
        // note:
        // need set alpha because (maybe) SDK forget set alpha back
        titleViewContainer.alpha = 1
    }
}

extension SearchViewController {
    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemGroupedBackgroundColor
    }

    private func setupSearchBar() {
        searchBar.placeholder = L10n.Scene.Search.SearchBar.placeholder
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        titleViewContainer.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: titleViewContainer.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: titleViewContainer.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: titleViewContainer.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: titleViewContainer.bottomAnchor),
        ])
        navigationItem.titleView = titleViewContainer

        searchBarTapPublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] in
                guard let self = self else { return }
                // push to search detail
                let searchDetailViewModel = SearchDetailViewModel()
                searchDetailViewModel.needsBecomeFirstResponder = true
                self.navigationController?.delegate = self.searchTransitionController
                self.coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .customPush)
            }
            .store(in: &disposeBag)
    }

}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        searchBarTapPublisher.send()
        return false
    }
}

// MARK: - UISearchControllerDelegate
extension SearchViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        searchController.isActive = true
    }
    func didPresentSearchController(_ searchController: UISearchController) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
}

// MARK: - UICollectionViewDelegate
extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select item at: \(indexPath.debugDescription)")
        
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .trend(let hashtag):
            let viewModel = HashtagTimelineViewModel(context: context, hashtag: hashtag.name)
            coordinator.present(scene: .hashtagTimeline(viewModel: viewModel), from: self, transition: .show)
        }
    }
}
