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
    let searchHistoryFetchedResultController: SearchHistoryFetchedResultController

    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>!
    let activeMastodonAuthenticationObjectID = CurrentValueSubject<NSManagedObjectID?, Never>(nil)

    init(context: AppContext) {
        self.context = context
        self.searchHistoryFetchedResultController = SearchHistoryFetchedResultController(managedObjectContext: context.managedObjectContext)
        
        context.authenticationService.activeMastodonAuthentication
            .sink { [weak self] authentication in
                guard let self = self else { return }
                // bind search history
                self.searchHistoryFetchedResultController.domain.value = authentication?.domain
                self.searchHistoryFetchedResultController.userID.value = authentication?.userID
                
                // bind objectID
                self.activeMastodonAuthenticationObjectID.value = authentication?.objectID
            }
            .store(in: &disposeBag)
        
        try? searchHistoryFetchedResultController.fetchedResultsController.performFetch()
    }
    
}

extension SidebarViewModel {
    enum Section: Int, Hashable, CaseIterable {
        case tab
        case account
    }
    
    enum Item: Hashable {
        case tab(MainTabBarController.Tab)
        case searchHistory(SearchHistoryViewModel)
        case header(HeaderViewModel)
        case account(AccountViewModel)
        case addAccount
    }
    
    struct SearchHistoryViewModel: Hashable {
        let searchHistoryObjectID: NSManagedObjectID
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
        let tabCellRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, MainTabBarController.Tab> { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            
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
            let needsOutlineDisclosure = item == .search
            cell.item = SidebarListContentView.Item(
                image: item.sidebarImage,
                imageURL: imageURL,
                headline: headline,
                subheadline: nil,
                needsOutlineDisclosure: needsOutlineDisclosure
            )
            cell.setNeedsUpdateConfiguration()
            
            switch item {
            case .notification:
                Publishers.CombineLatest(
                    self.context.authenticationService.activeMastodonAuthentication,
                    self.context.notificationService.unreadNotificationCountDidUpdate
                )
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] authentication, _ in
                    guard let cell = cell else { return }
                    let hasUnreadPushNotification: Bool = authentication.flatMap { authentication in
                        let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: authentication.userAccessToken)
                        return count > 0
                    } ?? false
                    
                    let image = hasUnreadPushNotification ? UIImage(systemName: "bell.badge")! : UIImage(systemName: "bell")!
                    cell._contentView?.imageView.image = image
                }
                .store(in: &cell.disposeBag)
            default:
                break
            }
        }
        
        let searchHistoryCellRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, SearchHistoryViewModel> { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            let managedObjectContext = self.searchHistoryFetchedResultController.fetchedResultsController.managedObjectContext
            
            guard let searchHistory = try? managedObjectContext.existingObject(with: item.searchHistoryObjectID) as? SearchHistory else { return }

            if let account = searchHistory.account {
                let headline: MetaContent = {
                    do {
                        let content = MastodonContent(content: account.displayNameWithFallback, emojis: account.emojiMeta)
                        return try MastodonMetaContent.convert(document: content)
                    } catch {
                        return PlaintextMetaContent(string: account.displayNameWithFallback)
                    }
                }()
                cell.item = SidebarListContentView.Item(
                    image: .placeholder(color: .systemFill),
                    imageURL: account.avatarImageURL(),
                    headline: headline,
                    subheadline: PlaintextMetaContent(string: "@" + account.acctWithDomain),
                    needsOutlineDisclosure: false
                )
            } else if let hashtag = searchHistory.hashtag {
                let image = UIImage(systemName: "number.square.fill")!.withRenderingMode(.alwaysTemplate)
                let headline = PlaintextMetaContent(string: "#" + hashtag.name)
                cell.item = SidebarListContentView.Item(
                    image: image,
                    imageURL: nil,
                    headline: headline,
                    subheadline: nil,
                    needsOutlineDisclosure: false
                )
            } else {
                assertionFailure()
            }
            
            cell.setNeedsUpdateConfiguration()
        }
        
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderViewModel> { (cell, indexPath, item) in
            var content = UIListContentConfiguration.sidebarHeader()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure()]
        }
        
        let accountRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, AccountViewModel> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            
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
                subheadline: PlaintextMetaContent(string: "@" + user.acctWithDomain),
                needsOutlineDisclosure: false
            )
            cell.setNeedsUpdateConfiguration()
            
            // FIXME: use notification, not timer
            let accessToken = authentication.userAccessToken
            AppContext.shared.timestampUpdatePublisher
                .map { _ in UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken) }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] count in
                    guard let cell = cell else { return }
                    cell._contentView?.badgeButton.setBadge(number: count)
                }
                .store(in: &cell.disposeBag)
            
            let authenticationObjectID = item.authenticationObjectID
            self.activeMastodonAuthenticationObjectID
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] objectID in
                    guard let cell = cell else { return }
                    cell._contentView?.checkmarkImageView.isHidden = authenticationObjectID != objectID
                }
                .store(in: &cell.disposeBag)
        }
        
        let addAccountRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AddAccountViewModel> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = L10n.Scene.AccountList.addAccount
            content.image = UIImage(systemName: "plus.square.fill")!
            cell.contentConfiguration = content
            cell.accessories = []
        }
        
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tab(let tab):
                return collectionView.dequeueConfiguredReusableCell(using: tabCellRegistration, for: indexPath, item: tab)
            case .searchHistory(let viewModel):
                return collectionView.dequeueConfiguredReusableCell(using: searchHistoryCellRegistration, for: indexPath, item: viewModel)
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
        
        // update .search tab
        searchHistoryFetchedResultController.objectIDs
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objectIDs in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                // update .search tab
                var sectionSnapshot = diffableDataSource.snapshot(for: .tab)
                
                // remove children
                let searchHistorySnapshot = sectionSnapshot.snapshot(of: .tab(.search))
                sectionSnapshot.delete(searchHistorySnapshot.items)
                
                // append children
                let managedObjectContext = self.searchHistoryFetchedResultController.fetchedResultsController.managedObjectContext
                let items: [Item] = objectIDs.compactMap { objectID -> Item? in
                    guard let searchHistory = try? managedObjectContext.existingObject(with: objectID) as? SearchHistory else { return nil }
                    guard searchHistory.account != nil || searchHistory.hashtag != nil else { return nil }
                    let viewModel = SearchHistoryViewModel(searchHistoryObjectID: objectID)
                    return Item.searchHistory(viewModel)
                }
                sectionSnapshot.append(Array(items.prefix(5)), to: .tab(.search))
                sectionSnapshot.expand([.tab(.search)])
                
                // apply snapshot
                diffableDataSource.apply(sectionSnapshot, to: .tab, animatingDifferences: false)
            }
            .store(in: &disposeBag)
        
        // update .me tab and .account section
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
