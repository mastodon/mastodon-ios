//
//  SearchViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import GameplayKit
import MastodonSDK
import UIKit

final class SearchViewController: UIViewController, NeedsDependency {
    
    public static var hashtagCardHeight: CGFloat {
        get {
            if UIScreen.main.bounds.size.height > 736 {
                return 186
            }
            return 130
        }
    }
    
    public static var hashtagPeopleTalkingLabelTop: CGFloat {
        get {
            if UIScreen.main.bounds.size.height > 736 {
                return 18
            }
            return 6
        }
    }
    public static let accountCardHeight = 202
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = SearchViewModel(context: context, coordinator: coordinator)
    
    let statusBar: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.navigationBar.color
        return view
    }()
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = L10n.Scene.Search.Searchbar.placeholder
        searchBar.tintColor = Asset.Colors.brandBlue.color
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        let micImage = UIImage(systemName: "mic.fill")
        searchBar.setImage(micImage, for: .bookmark, state: .normal)
        searchBar.showsBookmarkButton = true
        searchBar.scopeButtonTitles = [L10n.Scene.Search.Searching.Segment.all, L10n.Scene.Search.Searching.Segment.people, L10n.Scene.Search.Searching.Segment.hashtags]
        searchBar.barTintColor = Asset.Colors.Background.navigationBar.color
        return searchBar
    }()
    
    // recommend
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.clipsToBounds = false
        return scrollView
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()
    
    let hashtagCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let view = ControlContainableCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.layer.masksToBounds = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let accountsCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let view = ControlContainableCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.layer.masksToBounds = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // searching
    let searchingTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = Asset.Colors.Background.systemBackground.color
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return tableView
    }()
    
    lazy var searchHeader: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        view.frame = CGRect(origin: .zero, size: CGSize(width: searchingTableView.frame.width, height: 56))
        return view
    }()
    
    let recentSearchesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Search.Searching.recentSearch
        return label
    }()
    
    let clearSearchHistoryButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton(type: .custom)
        button.setTitleColor(Asset.Colors.brandBlue.color, for: .normal)
        button.setTitle(L10n.Scene.Search.Searching.clear, for: .normal)
        return button
    }()
}

extension SearchViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        view.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        navigationItem.hidesBackButton = true
       
        setupSearchBar()
        setupScrollView()
        setupHashTagCollectionView()
        setupAccountsCollectionView()
        setupSearchingTableView()
        setupDataSource()
        setupSearchHeader()
        view.bringSubviewToFront(searchBar)
        view.bringSubviewToFront(statusBar)
    }

    func setupSearchBar() {
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusBar)
        NSLayoutConstraint.activate([
            statusBar.topAnchor.constraint(equalTo: view.topAnchor),
            statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 3),
        ])
    }

    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // scrollView
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: searchBar.frame.height),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),
        ])

        // stackview
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
    }
    
    func setupDataSource() {
        viewModel.hashtagDiffableDataSource = RecommendHashTagSection.collectionViewDiffableDataSource(for: hashtagCollectionView)
        viewModel.accountDiffableDataSource = RecommendAccountSection.collectionViewDiffableDataSource(for: accountsCollectionView, delegate: self, managedObjectContext: context.managedObjectContext)
        viewModel.searchResultDiffableDataSource = SearchResultSection.tableViewDiffableDataSource(for: searchingTableView, dependency: self)
    }
}

extension SearchViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == searchingTableView {
            handleScrollViewDidScroll(scrollView)
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.showsScopeBar = true
        viewModel.isSearching.value = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.showsScopeBar = false
        viewModel.isSearching.value = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.showsScopeBar = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        viewModel.isSearching.value = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText.send(searchText)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            viewModel.searchScope.value = Mastodon.API.Search.SearchType.default
        case 1:
            viewModel.searchScope.value = Mastodon.API.Search.SearchType.accounts
        case 2:
            viewModel.searchScope.value = Mastodon.API.Search.SearchType.hashtags
        default:
            break
        }
    }

    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {}
}

extension SearchViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = SearchViewModel.LoadOldestState.Loading
    var loadMoreConfigurableTableView: UITableView { searchingTableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { viewModel.loadoldestStateMachine }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchViewController_Previews: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            let viewController = SearchViewController()
            return viewController
        }
        .previewLayout(.fixed(width: 375, height: 800))
    }
}

#endif
