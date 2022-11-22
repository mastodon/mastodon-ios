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
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class CustomSearchController: UISearchController {
    
    let customSearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
    
    override var searchBar: UISearchBar { customSearchBar }
    
}

// Fake search bar not works on iPad with UISplitViewController
// check device and fallback to standard UISearchController
final class SearchDetailViewController: PageboyViewController, NeedsDependency {

    let logger = Logger(subsystem: "SearchDetail", category: "UI")

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let isPhoneDevice: Bool = {
        return UIDevice.current.userInterfaceIdiom == .phone
    }()

    var viewModel: SearchDetailViewModel!
    var viewControllers: [SearchResultViewController]!

    let navigationBarVisualEffectBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    let navigationBarBackgroundView = UIView()
    let navigationBar: UINavigationBar = {
        let navigationItem = UINavigationItem()
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance

        let navigationBar = UINavigationBar(
            frame: CGRect(x: 0, y: 0, width: 300, height: 100)
        )
        navigationBar.setItems([navigationItem], animated: false)
        return navigationBar
    }()
    
    let searchController: CustomSearchController = {
        let searchController = CustomSearchController()
        searchController.automaticallyShowsScopeBar = false
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()
    private(set) lazy var searchBar: UISearchBar = {
        let searchBar: UISearchBar
        if isPhoneDevice {
            searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        } else {
            searchBar = searchController.searchBar
            searchController.automaticallyShowsScopeBar = false
            searchController.searchBar.setShowsScope(true, animated: false)
        }
        searchBar.placeholder = L10n.Scene.Search.SearchBar.placeholder
        searchBar.scopeButtonTitles = SearchDetailViewModel.SearchScope.allCases.map { $0.segmentedControlTitle }
        searchBar.sizeToFit()
        searchBar.scopeBarBackgroundImage = UIImage()
        return searchBar
    }()

    private(set) lazy var searchHistoryViewController: SearchHistoryViewController = {
        let searchHistoryViewController = SearchHistoryViewController()
        searchHistoryViewController.context = context
        searchHistoryViewController.coordinator = coordinator
        searchHistoryViewController.viewModel = SearchHistoryViewModel(context: context, authContext: viewModel.authContext)
        return searchHistoryViewController
    }()
}

extension SearchDetailViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        setupSearchBar()
        
        addChild(searchHistoryViewController)
        searchHistoryViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchHistoryViewController.view)
        searchHistoryViewController.didMove(toParent: self)
        if isPhoneDevice {
            NSLayoutConstraint.activate([
                searchHistoryViewController.view.topAnchor.constraint(equalTo: navigationBarBackgroundView.bottomAnchor),
                searchHistoryViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                searchHistoryViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                searchHistoryViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } else {
            searchHistoryViewController.view.pinToParent()
        }

        transition = Transition(style: .fade, duration: 0.1)
        isScrollEnabled = false

        viewControllers = viewModel.searchScopes.map { scope in
            let searchResultViewController = SearchResultViewController()
            searchResultViewController.context = context
            searchResultViewController.coordinator = coordinator
            searchResultViewController.viewModel = SearchResultViewModel(context: context, authContext: viewModel.authContext, searchScope: scope)

            // bind searchText
            viewModel.searchText
                .assign(to: \.value, on: searchResultViewController.viewModel.searchText)
                .store(in: &searchResultViewController.disposeBag)

            // bind navigationBarFrame
            viewModel.navigationBarFrame
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, on: searchResultViewController.viewModel.navigationBarFrame)
                .store(in: &searchResultViewController.disposeBag)
            return searchResultViewController
        }

        // set initial items from "all" search scope for non-appeared lists
        if let allSearchScopeViewController = viewControllers.first(where: { $0.viewModel.searchScope == .all }) {
            allSearchScopeViewController.viewModel.$items
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
                            viewController.viewModel.userFetchedResultsController.userIDs = allSearchScopeViewController.viewModel.userFetchedResultsController.userIDs
                        case .hashtags:
                            viewController.viewModel.hashtags = allSearchScopeViewController.viewModel.hashtags
                        case .posts:
                            viewController.viewModel.statusFetchedResultsController.statusIDs = allSearchScopeViewController.viewModel.statusFetchedResultsController.statusIDs
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
            .removeDuplicates()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] searchText in
                guard let self = self else { return }
                guard let searchResultViewController = self.currentViewController as? SearchResultViewController else {
                    return
                }
                self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): trigger search \(searchText)")
                searchResultViewController.viewModel.stateMachine.enter(SearchResultViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)

        // bind search history display
        viewModel.searchText
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.searchHistoryViewController.view.isHidden = !searchText.isEmpty
            }
            .store(in: &disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isPhoneDevice {
            navigationController?.setNavigationBarHidden(true, animated: animated)
            searchBar.setShowsScope(true, animated: false)
            searchBar.setNeedsLayout()
            searchBar.layoutIfNeeded()
        } else {
            // do nothing
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isPhoneDevice {
            if !isModal {
                // prevent bar restore conflict with modal style issue
                navigationController?.setNavigationBarHidden(false, animated: animated)
            }
        } else {
            // do nothing
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isPhoneDevice {
            searchBar.setShowsCancelButton(true, animated: animated)
            UIView.performWithoutAnimation {
                self.searchBar.becomeFirstResponder()
            }
        } else {
            searchController.searchBar.setShowsCancelButton(true, animated: false)
            searchController.searchBar.setShowsScope(true, animated: false)
            UIView.performWithoutAnimation {
                self.searchController.isActive = true
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

}

extension SearchDetailViewController {
    private func setupSearchBar() {
        if isPhoneDevice {
            navigationBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(navigationBar)
            NSLayoutConstraint.activate([
                navigationBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
                navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            navigationBar.topItem?.titleView = searchBar
            navigationBar.layer.observe(\.bounds, options: [.new]) { [weak self] navigationBar, _ in
                guard let self = self else { return }
                self.viewModel.navigationBarFrame.value = navigationBar.frame
            }
            .store(in: &observations)
            
            navigationBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(navigationBarBackgroundView, belowSubview: navigationBar)
            NSLayoutConstraint.activate([
                navigationBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
                navigationBarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationBarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navigationBarBackgroundView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            ])
            
            navigationBarVisualEffectBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(navigationBarVisualEffectBackgroundView, belowSubview: navigationBarBackgroundView)
            navigationBarVisualEffectBackgroundView.pinTo(to: navigationBarBackgroundView)
        } else {
            navigationItem.setHidesBackButton(true, animated: false)
            navigationItem.titleView = nil
            navigationItem.searchController = searchController
            searchController.searchBar.sizeToFit()
        }

        searchBar.text = viewModel.searchText.value
        searchBar.delegate = self
    }

    private func setupBackgroundColor(theme: Theme) {
        navigationBarBackgroundView.backgroundColor = theme.navigationBarBackgroundColor
        navigationBar.tintColor = Asset.Colors.brand.color
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

        // dismiss or pop
        if isModal {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: false)
        }
    }

}

// MARK: - PageboyViewControllerDataSource
extension SearchDetailViewController: PageboyViewControllerDataSource {

    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
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
