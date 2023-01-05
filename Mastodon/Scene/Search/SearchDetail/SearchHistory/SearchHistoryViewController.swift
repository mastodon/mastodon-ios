//
//  SearchHistoryViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonCore

final class SearchHistoryViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "SearchHistoryViewController", category: "ViewController")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchHistoryViewModel!
    
    let collectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
}

extension SearchHistoryViewController {

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

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.pinToParent()
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            searchHistorySectionHeaderCollectionReusableViewDelegate: self
        )
    }
}

extension SearchHistoryViewController {
    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemGroupedBackgroundColor
    }
}

// MARK: - UICollectionViewDelegate
extension SearchHistoryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select item at: \(indexPath.debugDescription)")
        
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
            case .user(let record):
                await DataSourceFacade.coordinateToProfileScene(
                    provider: self,
                    user: record
                )
            case .hashtag(let record):
                await DataSourceFacade.coordinateToHashtagScene(
                    provider: self,
                    tag: record
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
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        Task {
            try await DataSourceFacade.responseToDeleteSearchHistory(
                provider: self
            )
        }
    }
}
