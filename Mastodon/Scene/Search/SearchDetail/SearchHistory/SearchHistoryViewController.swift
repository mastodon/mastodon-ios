//
//  SearchHistoryViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import UIKit
import Combine
import CoreDataStack
import MastodonCore
import MastodonUI

final class SearchHistoryViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
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
}

extension SearchHistoryViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.pinToParent()
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            searchHistorySectionHeaderCollectionReusableViewDelegate: self
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        viewModel.items = (try? FileManager.default.searchItems(for: authContext.mastodonAuthenticationBox)) ?? []
    }
}

// MARK: - UICollectionViewDelegate
extension SearchHistoryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }

        Task {
            let source = DataSourceItem.Source(indexPath: indexPath)
            guard let item = await item(from: source) else {
                return
            }

            await DataSourceFacade.responseToCreateSearchHistory(
                provider: self,
                item: item
            )

            switch item {
                case .account(account: let account, relationship: _):
                    DataSourceFacade.coordinateToProfileScene(provider: self, account: account)

                case .hashtag(let tag):
                    await DataSourceFacade.coordinateToHashtagScene(
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
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - SearchHistorySectionHeaderCollectionReusableViewDelegate
extension SearchHistoryViewController: SearchHistorySectionHeaderCollectionReusableViewDelegate {
    func searchHistorySectionHeaderCollectionReusableView(
        _ searchHistorySectionHeaderCollectionReusableView: SearchHistorySectionHeaderCollectionReusableView,
        clearButtonDidPressed button: UIButton
    ) {
        FileManager.default.removeSearchHistory(for: authContext.mastodonAuthenticationBox)
        viewModel.items = []
    }
}

//MARK: - SearchResultOverviewCoordinatorDelegate
extension SearchHistoryViewController: SearchResultOverviewCoordinatorDelegate {
    func newSearchHistoryItemAdded(_ coordinator: SearchResultOverviewCoordinator) {
        viewModel.items = (try? FileManager.default.searchItems(for: authContext.mastodonAuthenticationBox)) ?? []
    }
}
