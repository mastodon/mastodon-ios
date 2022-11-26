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
import MastodonCore
import MastodonLocalization

final class HeightFixedSearchBar: UISearchBar {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: 36)
    }
}

final class SearchViewController: UIViewController, NeedsDependency {

    let logger = Logger(subsystem: "SearchViewController", category: "ViewController")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var searchTransitionController = SearchTransitionController()

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchViewModel!

    // use AutoLayout could set search bar margin automatically to
    // layout alongside with split mode button (on iPad)
    let titleViewContainer = UIView()
    let searchBar = HeightFixedSearchBar()

//    let collectionView: UICollectionView = {
//        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
//        configuration.backgroundColor = .clear
//        configuration.headerMode = .supplementary
//        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .clear
//        return collectionView
//    }()

    // value is the initial search text to set
    let searchBarTapPublisher = PassthroughSubject<String, Never>()
    
    private(set) lazy var discoveryViewController: DiscoveryViewController? = {
        guard let authContext = viewModel.authContext else { return nil }
        let viewController = DiscoveryViewController()
        viewController.context = context
        viewController.coordinator = coordinator
        viewController.viewModel = .init(
            context: context,
            coordinator: coordinator,
            authContext: authContext
        )
        return viewController
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension SearchViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupAppearance(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupAppearance(theme: theme)
            }
            .store(in: &disposeBag)

        title = L10n.Scene.Search.title

        setupSearchBar()

//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(collectionView)
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//
//        collectionView.delegate = self
//        viewModel.setupDiffableDataSource(
//            collectionView: collectionView
//        )
        
        guard let discoveryViewController = self.discoveryViewController else { return }

        addChild(discoveryViewController)
        discoveryViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(discoveryViewController.view)
        discoveryViewController.view.pinToParent()

//        discoveryViewController.view.isHidden = true

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
    private func setupAppearance(theme: Theme) {
        view.backgroundColor = theme.systemGroupedBackgroundColor

        // Match the DiscoveryViewController tab color and remove the double separator.
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = theme.systemBackgroundColor
        navigationBarAppearance.shadowColor = nil

        navigationItem.standardAppearance = navigationBarAppearance
        navigationItem.scrollEdgeAppearance = navigationBarAppearance
        navigationItem.compactAppearance = navigationBarAppearance

        if #available(iOS 15, *) {
            navigationItem.compactScrollEdgeAppearance = navigationBarAppearance
        }
    }

    private func setupSearchBar() {
        searchBar.placeholder = L10n.Scene.Search.SearchBar.placeholder
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        titleViewContainer.addSubview(searchBar)
        searchBar.pinToParent()
        searchBar.setContentHuggingPriority(.required, for: .horizontal)
        searchBar.setContentHuggingPriority(.required, for: .vertical)
        navigationItem.titleView = titleViewContainer
//        navigationItem.titleView = searchBar

        searchBarTapPublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] initialText in
                guard let self = self else { return }
                // push to search detail
                guard let authContext = self.viewModel.authContext else { return }
                let searchDetailViewModel = SearchDetailViewModel(authContext: authContext, initialSearchText: initialText)
                searchDetailViewModel.needsBecomeFirstResponder = true
                self.navigationController?.delegate = self.searchTransitionController
                // FIXME:
                // use `.customPush(animated: false)` false to disable navigation bar animation for searchBar layout
                // but that should be a fade transition whe fixed size searchBar
                _ = self.coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .customPush(animated: false))
            }
            .store(in: &disposeBag)
    }

}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        searchBarTapPublisher.send("")
        return false
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.text = ""
        searchBarTapPublisher.send(searchText)
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

// MARK: - ScrollViewContainer
extension SearchViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        discoveryViewController?.scrollView ?? UIScrollView()
    }
    func scrollToTop(animated: Bool) {
        discoveryViewController?.scrollToTop(animated: animated)
    }
}

// MARK: - UICollectionViewDelegate
//extension SearchViewController: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select item at: \(indexPath.debugDescription)")
//
//        defer {
//            collectionView.deselectItem(at: indexPath, animated: true)
//        }
//
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//
//        switch item {
//        case .trend(let hashtag):
//            let viewModel = HashtagTimelineViewModel(context: context, hashtag: hashtag.name)
//            coordinator.present(scene: .hashtagTimeline(viewModel: viewModel), from: self, transition: .show)
//        }
//    }
//}
