//
//  SearchDetailViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import os.log
import UIKit
import Combine
import Pageboy

final class SearchDetailViewController: PageboyViewController, NeedsDependency {

    let logger = Logger(subsystem: "SearchDetail", category: "UI")

    var disposeBag = Set<AnyCancellable>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var viewModel: SearchDetailViewModel!
    var viewControllers: [SearchResultViewController]!

    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = L10n.Scene.Search.SearchBar.placeholder
        searchBar.scopeButtonTitles = SearchDetailViewModel.SearchScope.allCases.map { $0.segmentedControlTitle }
        return searchBar
    }()
}

extension SearchDetailViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.setHidesBackButton(true, animated: false)
        setupSearchBar()

        transition = Transition(style: .fade, duration: 0.1)
        // transition = nil
        isScrollEnabled = false

        viewControllers = viewModel.searchScopes.map { scope in
            let searchResultViewController = SearchResultViewController()
            searchResultViewController.context = context
            searchResultViewController.coordinator = coordinator
            searchResultViewController.viewModel = SearchResultViewModel(context: context, searchScope: scope)
            // bind searchText
            viewModel.searchText
                .assign(to: \.value, on: searchResultViewController.viewModel.searchText)
                .store(in: &searchResultViewController.disposeBag)
            return searchResultViewController
        }

        // set initial items from "all" search scope for non-appeared lists
        if let allSearchScopeViewController = viewControllers.first(where: { $0.viewModel.searchScope == .all }) {
            allSearchScopeViewController.viewModel.items
                .receive(on: DispatchQueue.main)
                .sink { [weak self] items in
                    guard let self = self else { return }
                    guard self.currentViewController === allSearchScopeViewController else { return }
                    for viewController in self.viewControllers where viewController != allSearchScopeViewController {
                        // do not change appeared list
                        guard !viewController.viewModel.viewDidAppear.value else { continue }
                        // set initial items
                        switch viewController.viewModel.searchScope {
                        case .all:
                            assertionFailure()
                            break
                        case .people:
                            viewController.viewModel.items.value = items.filter { item in
                                guard case .account = item else { return false }
                                return true
                            }
                        case .hashtags:
                            viewController.viewModel.items.value = items.filter { item in
                                guard case .hashtag = item else { return false }
                                return true
                            }
                        case .posts:
                            viewController.viewModel.items.value = items.filter { item in
                                guard case .status = item else { return false }
                                return true
                            }
                        }
                    }
                }
                .store(in: &allSearchScopeViewController.disposeBag)
        }

        dataSource = self
        delegate = self

        // bind search bar scope
        viewModel.selectedSearchScope
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchScope in
                guard let self = self else { return }
                if let index = self.viewModel.searchScopes.firstIndex(of: searchScope) {
                    self.searchBar.selectedScopeButtonIndex = index
                    self.scrollToPage(.at(index: index), animated: true)
                }
            }
            .store(in: &disposeBag)

        // bind search trigger
        viewModel.searchText
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self else { return }
                guard let searchResultViewController = self.currentViewController as? SearchResultViewController else {
                    return
                }
                self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): trigger search \(searchText)")
                searchResultViewController.viewModel.stateMachine.enter(SearchResultViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        searchBar.setShowsCancelButton(true, animated: animated)
        searchBar.becomeFirstResponder()
    }

}

extension SearchDetailViewController {
    private func setupSearchBar() {
        navigationItem.titleView = searchBar
        searchBar.setShowsScope(true, animated: false)
        searchBar.sizeToFit()

        searchBar.delegate = self
    }
}

// MARK: - UISearchBarDelegate
extension SearchDetailViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.selectedSearchScope.value = viewModel.searchScopes[selectedScope]
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): searchTest \(searchText)")
        viewModel.searchText.value = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        navigationController?.popViewController(animated: true)
    }

}

// MARK: - PageboyViewControllerDataSource
extension SearchDetailViewController: PageboyViewControllerDataSource {

    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return 4
    }

    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        guard index < viewControllers.count else { return nil }
        return viewControllers[index]
    }

    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }

}

// MARK: - PageboyViewControllerDelegate
extension SearchDetailViewController: PageboyViewControllerDelegate {

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        willScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        // do nothing
    }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollTo position: CGPoint,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        // do nothing
    }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didCancelScrollToPageAt index: PageboyViewController.PageIndex,
        returnToPageAt previousIndex: PageboyViewController.PageIndex
    ) {
        // do nothing
    }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): index \(index)")

        let searchResultViewController = viewControllers[index]
        viewModel.selectedSearchScope.value = searchResultViewController.viewModel.searchScope

        // trigger fetch
        searchResultViewController.viewModel.stateMachine.enter(SearchResultViewModel.State.Loading.self)
    }


    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didReloadWith currentViewController: UIViewController,
        currentPageIndex: PageboyViewController.PageIndex
    ) {
        // do nothing
    }
}
