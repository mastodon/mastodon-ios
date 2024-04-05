//
//  SearchViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonCore
import MastodonLocalization
import Pageboy

final class SearchViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var searchTransitionController = SearchTransitionController()

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchViewModel?

    // use AutoLayout could set search bar margin automatically to
    // layout alongside with split mode button (on iPad)
    let searchBar = UISearchBar()

    // value is the initial search text to set
    let searchBarTapPublisher = PassthroughSubject<String, Never>()
    
    private(set) lazy var discoveryViewController: DiscoveryViewController? = {
        guard let authContext = viewModel?.authContext else { return nil }
        let viewController = DiscoveryViewController()
        viewController.context = context
        viewController.coordinator = coordinator
        viewController.viewModel = .init(
            context: context,
            coordinator: coordinator,
            authContext: authContext
        )
        viewController.delegate = self
        return viewController
    }()

    let segmentedControl: UISegmentedControl
    let segmentedControlBackground: UIView

    init() {
        segmentedControl = UISegmentedControl(items: [
            L10n.Scene.Discovery.Tabs.posts,
            L10n.Scene.Discovery.Tabs.hashtags,
            L10n.Scene.Discovery.Tabs.news,
            L10n.Scene.Discovery.Tabs.forYou
        ])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0

        segmentedControlBackground = UIView()
        segmentedControlBackground.translatesAutoresizingMaskIntoConstraints = false
        segmentedControlBackground.backgroundColor = .systemBackground

        super.init(nibName: nil, bundle: nil)

        segmentedControl.addTarget(self, action: #selector(SearchViewController.segmentedControlValueChanged(_:)), for: .valueChanged)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAppearance()

        title = L10n.Scene.Search.title

        setupSearchBar()
        guard let discoveryViewController else { return }

        segmentedControlBackground.addSubview(segmentedControl)
        view.addSubview(segmentedControlBackground)


        addChild(discoveryViewController)
        discoveryViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(discoveryViewController.view)
        discoveryViewController.didMove(toParent: self)

        let constraints = [
            segmentedControl.topAnchor.constraint(equalTo: segmentedControlBackground.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: segmentedControlBackground.leadingAnchor, constant: 8),
            segmentedControlBackground.trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 8),
            segmentedControlBackground.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),

            segmentedControlBackground.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedControlBackground.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: segmentedControlBackground.trailingAnchor),

            discoveryViewController.view.topAnchor.constraint(equalTo: segmentedControlBackground.bottomAnchor),
            discoveryViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: discoveryViewController.view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: discoveryViewController.view.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        searchBar.scopeBarBackgroundImage = .placeholder(color: .systemBackground)
    }

    private func setupAppearance() {
        view.backgroundColor = .systemGroupedBackground

        // Match the DiscoveryViewController tab color and remove the double separator.
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .systemBackground
        navigationBarAppearance.shadowColor = nil

        navigationItem.standardAppearance = navigationBarAppearance
        navigationItem.scrollEdgeAppearance = navigationBarAppearance
        navigationItem.compactAppearance = navigationBarAppearance
        navigationItem.compactScrollEdgeAppearance = navigationBarAppearance
    }

    private func setupSearchBar() {
        searchBar.placeholder = L10n.Scene.Search.SearchBar.placeholder
        searchBar.delegate = self
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar

        searchBarTapPublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] initialText in
                guard let self = self else { return }
                // push to search detail
                guard let authContext = self.viewModel?.authContext else { return }
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

    @objc
    private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        discoveryViewController?.scrollToPage(.at(index: sender.selectedSegmentIndex), animated: true)
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

//MARK: - PageboyViewControllerDelegate
extension SearchViewController: PageboyViewControllerDelegate {
    func pageboyViewController(_ pageboyViewController: Pageboy.PageboyViewController, didReloadWith currentViewController: UIViewController, currentPageIndex: Pageboy.PageboyViewController.PageIndex) {
        // do nothing
    }
    
    func pageboyViewController(_ pageboyViewController: Pageboy.PageboyViewController, didScrollTo position: CGPoint, direction: Pageboy.PageboyViewController.NavigationDirection, animated: Bool) {
        // do nothing
    }

    func pageboyViewController(_ pageboyViewController: PageboyViewController, willScrollToPageAt index: PageboyViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        // do nothing
    }

    func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: PageboyViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        segmentedControl.selectedSegmentIndex = index
    }
}
