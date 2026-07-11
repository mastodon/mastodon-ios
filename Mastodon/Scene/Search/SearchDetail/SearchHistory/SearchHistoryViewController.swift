//
//  SearchHistoryViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import UIKit
import MastodonCore
import MastodonUI
import MastodonLocalization
import MastodonAsset

final class SearchHistoryViewController: UIViewController {

    var viewModel: SearchHistoryViewModel!
    
    let collectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.separatorConfiguration.bottomSeparatorInsets.leading = 62
        configuration.separatorConfiguration.topSeparatorInsets.leading = 62
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.keyboardDismissMode = .onDrag
        return collectionView
    }()

    private let noSearchResultLabel: UILabel = {
        let label: UILabel = UILabel()
        label.text = L10n.Scene.Search.Searching.noRecentSearches
        label.textColor = .secondaryLabel
        label.isHidden = true  // Initially Hiden
        return label
    }()
}

extension SearchHistoryViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.pinToParent()
        self.setupNoSearchResultLabel()
        updateNoRecentSearchLabelUI()
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            searchHistorySectionHeaderCollectionReusableViewDelegate: self
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        viewModel.items = (try? FileManager.default.searchItems(for: authenticationBox)) ?? []
    }

    private func setupNoSearchResultLabel() {
        noSearchResultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noSearchResultLabel)
        NSLayoutConstraint.activate([
            noSearchResultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noSearchResultLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 200).priority(.defaultHigh),
            noSearchResultLabel.centerYAnchor.constraint(lessThanOrEqualTo: view.centerYAnchor)
        ])
    }

    private func updateNoRecentSearchLabelUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.noSearchResultLabel.isHidden = !self.viewModel.isRecentSearchEmpty
        }
    }
}

// MARK: - UICollectionViewDelegate
extension SearchHistoryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }

        Task {
            let source = LegacyDataSourceFacade.DataSourceItem.Source(indexPath: indexPath)
            guard let item = await item(from: source) else {
                return
            }

            await LegacyDataSourceFacade.responseToCreateSearchHistory(
                provider: self,
                item: item
            )

            switch item {
            case .account(account: let account, relationship: _):
                guard let myAccount = authenticationBox.cachedAccount else { return }
                let navigator = MastodonNavigationRouter()
                navigator.push(.profile(account: account, relationship: nil))
                
            case .hashtag(let tag):
                await LegacyDataSourceFacade.coordinateToHashtagScene(
                    provider: self,
                    tag: tag
                )
            default:
                assertionFailure()
                break
            }
        }
    }

}

// MARK: - AuthContextProvider
extension SearchHistoryViewController: AuthContextProvider {
    var authenticationBox: MastodonAuthenticationBox { viewModel.authenticationBox }
}

// MARK: - SearchHistorySectionHeaderCollectionReusableViewDelegate
extension SearchHistoryViewController: SearchHistorySectionHeaderCollectionReusableViewDelegate {
    func searchHistorySectionHeaderCollectionReusableView(
        _ searchHistorySectionHeaderCollectionReusableView: SearchHistorySectionHeaderCollectionReusableView,
        clearButtonDidPressed button: UIButton
    ) {
        FileManager.default.removeSearchHistory(for: authenticationBox)
        viewModel.items = []
        self.updateNoRecentSearchLabelUI()
    }
}

//MARK: - SearchResultOverviewCoordinatorDelegate
extension SearchHistoryViewController: SearchResultOverviewCoordinatorDelegate {
    func newSearchHistoryItemAdded(_ coordinator: SearchResultOverviewCoordinator) {
        viewModel.items = (try? FileManager.default.searchItems(for: authenticationBox)) ?? []
        self.updateNoRecentSearchLabelUI()
    }
}
