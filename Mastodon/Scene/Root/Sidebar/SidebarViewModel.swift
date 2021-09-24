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
import Meta
import MastodonMeta

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
        let tabCellRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, MainTabBarController.Tab> { (cell, indexPath, item) in
            let imageURL: URL? = {
                switch item {
                case .me:
                    let authentication = self.context.authenticationService.activeMastodonAuthentication.value
                    return authentication?.user.avatarImageURL()
                default:
                    return nil
                }
            }()
            let headline: MetaContent = {
                switch item {
                case .me:
                    return PlaintextMetaContent(string: item.title)
                    // TODO:
                    // return PlaintextMetaContent(string: "Myself")
                default:
                    return PlaintextMetaContent(string: item.title)
                }
            }()
            cell.item = SidebarListContentView.Item(
                image: item.sidebarImage,
                imageURL: imageURL,
                headline: headline,
                subheadline: nil
            )
            cell.setNeedsUpdateConfiguration()
        }
        
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderViewModel> { (cell, indexPath, item) in
            var content = UIListContentConfiguration.sidebarHeader()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure()]
        }
        
        let accountRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, AccountViewModel> { (cell, indexPath, item) in
            let authentication = AppContext.shared.managedObjectContext.object(with: item.authenticationObjectID) as! MastodonAuthentication
            let user = authentication.user
            let imageURL = user.avatarImageURL()
            let headline: MetaContent = {
                do {
                    let content = MastodonContent(content: user.displayNameWithFallback, emojis: user.emojiMeta)
                    return try MastodonMetaContent.convert(document: content)
                } catch {
                    return PlaintextMetaContent(string: user.displayNameWithFallback)
                }
            }()
            cell.item = SidebarListContentView.Item(
                image: .placeholder(color: .systemFill),
                imageURL: imageURL,
                headline: headline,
                subheadline: PlaintextMetaContent(string: "@" + user.acctWithDomain)
            )
            cell.setNeedsUpdateConfiguration()
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
                return collectionView.dequeueConfiguredReusableCell(using: tabCellRegistration, for: indexPath, item: tab)
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
                // tab
                var snapshot = self.diffableDataSource.snapshot()
                snapshot.reloadItems([.tab(.me)])
                self.diffableDataSource.apply(snapshot)
                
                // account
                var accountSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
                let headerItem = Item.header(HeaderViewModel(title: "Accounts"))
                accountSectionSnapshot.append([headerItem], to: nil)
                let accountItems = authentications.map { authentication in
                    Item.account(AccountViewModel(authenticationObjectID: authentication.objectID))
                }
                accountSectionSnapshot.append(accountItems, to: headerItem)
                accountSectionSnapshot.append([.addAccount], to: headerItem)
                accountSectionSnapshot.expand([headerItem])
                self.diffableDataSource.apply(accountSectionSnapshot, to: .account)
            }
            .store(in: &disposeBag)
    }

}
