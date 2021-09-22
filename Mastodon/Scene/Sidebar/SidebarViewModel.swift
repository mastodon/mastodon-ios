//
//  SidebarViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

final class SidebarViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>!

    
    init(context: AppContext) {
        self.context = context
    }
    
}

extension SidebarViewModel {
    enum Section: Hashable, CaseIterable {
        case tab
        case account
    }
    
    enum Item: Hashable {
        case tab(MainTabBarController.Tab)
        case header(HeaderViewModel)
        case account(AccountViewModel)
        case addAccount
    }
    
    struct HeaderViewModel: Hashable {
        let title: String
    }
    
    struct AccountViewModel: Hashable {
        let authenticationObjectID: NSManagedObjectID
    }
    
    struct AddAccountViewModel: Hashable {
        let id = UUID()
    }
}

extension SidebarViewModel {
    func setupDiffableDataSource(
        collectionView: UICollectionView
    ) {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MainTabBarController.Tab> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.image = item.image
            cell.contentConfiguration = content
            cell.accessories = []
        }
        
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderViewModel> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure()]
        }
        
        let accountRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AccountViewModel> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            let authentication = AppContext.shared.managedObjectContext.object(with: item.authenticationObjectID) as! MastodonAuthentication
            content.text = authentication.user.acctWithDomain
            content.image = nil
            cell.contentConfiguration = content
            cell.accessories = []
        }
        
        let addAccountRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AddAccountViewModel> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = L10n.Scene.AccountList.addAccount
            content.image = nil
            cell.contentConfiguration = content
            cell.accessories = []
        }
        
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tab(let tab):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: tab)
            case .header(let viewModel):
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: viewModel)
            case .account(let viewModel):
                return collectionView.dequeueConfiguredReusableCell(using: accountRegistration, for: indexPath, item: viewModel)
            case .addAccount:
                return collectionView.dequeueConfiguredReusableCell(using: addAccountRegistration, for: indexPath, item: AddAccountViewModel())
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        diffableDataSource.apply(snapshot)
        
        for section in Section.allCases {
            switch section {
            case .tab:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
                let items: [Item] = [
                    .tab(.home),
                    .tab(.search),
                    .tab(.notification),
                    .tab(.me),
                ]
                sectionSnapshot.append(items, to: nil)
                diffableDataSource.apply(sectionSnapshot, to: section)
            case .account:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
                let headerItem = Item.header(HeaderViewModel(title: "Accounts"))
                sectionSnapshot.append([headerItem], to: nil)
                sectionSnapshot.append([], to: headerItem)
                sectionSnapshot.append([.addAccount], to: headerItem)
                sectionSnapshot.expand([headerItem])
                diffableDataSource.apply(sectionSnapshot, to: section)
            }
        }
        
        context.authenticationService.mastodonAuthentications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authentications in
                guard let self = self else { return }
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
                let headerItem = Item.header(HeaderViewModel(title: "Accounts"))
                sectionSnapshot.append([headerItem], to: nil)
                let items = authentications.map { authentication in
                    Item.account(AccountViewModel(authenticationObjectID: authentication.objectID))
                }
                sectionSnapshot.append(items, to: headerItem)
                sectionSnapshot.append([.addAccount], to: headerItem)
                sectionSnapshot.expand([headerItem])
                self.diffableDataSource.apply(sectionSnapshot, to: .account)
            }
            .store(in: &disposeBag)
    }

}
