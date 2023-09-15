//
//  SearchDetailViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization

final class CustomSearchController: UISearchController {
    
    let customSearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
    
    override var searchBar: UISearchBar { customSearchBar }
    
}

// Fake search bar not works on iPad with UISplitViewController
// check device and fallback to standard UISearchController
final class SearchDetailViewController: UIViewController, NeedsDependency {
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let isPhoneDevice: Bool = {
        return UIDevice.current.userInterfaceIdiom == .phone
    }()

    var viewModel: SearchDetailViewModel!

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
        searchBar.sizeToFit()
        return searchBar
    }()

    private(set) lazy var searchHistoryViewController: SearchHistoryViewController = {
        let searchHistoryViewController = SearchHistoryViewController()
        searchHistoryViewController.context = context
        searchHistoryViewController.coordinator = coordinator
        searchHistoryViewController.viewModel = SearchHistoryViewModel(context: context, authContext: viewModel.authContext)
        return searchHistoryViewController
    }()

    private(set) lazy var searchResultsOverviewViewController: SearchResultsOverviewTableViewController = {
        let searchResultsOverviewViewController = SearchResultsOverviewTableViewController(appContext: context, authContext: viewModel.authContext)
        return searchResultsOverviewViewController
    }()

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

        searchResultsOverviewViewController.delegate = self

        addChild(searchResultsOverviewViewController)
        searchResultsOverviewViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultsOverviewViewController.view)
        searchResultsOverviewViewController.didMove(toParent: self)
        if isPhoneDevice {
            NSLayoutConstraint.activate([
                searchResultsOverviewViewController.view.topAnchor.constraint(equalTo: navigationBarBackgroundView.bottomAnchor),
                searchResultsOverviewViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                searchResultsOverviewViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                searchResultsOverviewViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } else {
            searchResultsOverviewViewController.view.pinToParent()
        }

        // bind search trigger
        // "local" search
        viewModel.searchText
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchText in
                guard let self else { return }

                self.searchResultsOverviewViewController.showStandardSearch(for: searchText)
            }
            .store(in: &disposeBag)

        // delayed search on server
        viewModel.searchText
            .removeDuplicates()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] searchText in
                guard let self else { return }

                self.searchResultsOverviewViewController.searchForSuggestions(for: searchText)
            }
            .store(in: &disposeBag)

        // bind search history display
        viewModel.searchText
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchText in
                guard let self = self else { return }

                self.searchHistoryViewController.view.isHidden = !searchText.isEmpty
                self.searchResultsOverviewViewController.view.isHidden = searchText.isEmpty
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

        searchBar.delegate = self
    }

    private func setupBackgroundColor(theme: Theme) {
        navigationBarBackgroundView.backgroundColor = theme.navigationBarBackgroundColor
        navigationBar.tintColor = Asset.Colors.Brand.blurple.color
    }
}

// MARK: - UISearchBarDelegate
extension SearchDetailViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText.value = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // dismiss or pop
        if isModal {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: false)
        }
    }
}

//MARK: SearchResultsOverviewViewControllerDelegate
extension SearchDetailViewController: SearchResultsOverviewTableViewControllerDeleagte {
    func showPosts(_ viewController: UIViewController) {
        //TODO: Implement
    }

    func showPeople(_ viewController: UIViewController) {
        //TODO: Implement
    }

    func showProfile(_ viewController: UIViewController) {
        //TODO: Implement
    }

    func openLink(_ viewController: UIViewController) {
        //TODO: Implement
    }
}
