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
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var searchTransitionController = SearchTransitionController()

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchViewModel!

    // use AutoLayout could set search bar margin automatically to
    // layout alongside with split mode button (on iPad)
    let titleViewContainer = UIView()
    let searchBar = HeightFixedSearchBar()

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
        guard let discoveryViewController = self.discoveryViewController else { return }

        addChild(discoveryViewController)
        discoveryViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(discoveryViewController.view)
        discoveryViewController.view.pinToParent()
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
        navigationItem.compactScrollEdgeAppearance = navigationBarAppearance
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
        searchController.isActive = true
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
