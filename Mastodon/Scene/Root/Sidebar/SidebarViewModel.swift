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
import MastodonAsset
import MastodonLocalization

final class SidebarViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    @Published private var isSidebarDataSourceReady = false
    @Published private var isAvatarButtonDataReady = false
    @Published var currentTab: MainTabBarController.Tab = .home

    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>?
    var secondaryDiffableDataSource: UICollectionViewDiffableDataSource<Section, Item>?
    @Published private(set) var isReadyForWizardAvatarButton = false

    let activeMastodonAuthenticationObjectID = CurrentValueSubject<NSManagedObjectID?, Never>(nil)

    init(context: AppContext) {
        self.context = context
        
        Publishers.CombineLatest(
            $isSidebarDataSourceReady,
            $isAvatarButtonDataReady
        )
        .map { $0 && $1 }
        .assign(to: &$isReadyForWizardAvatarButton)
        
        context.authenticationService.activeMastodonAuthentication
            .sink { [weak self] authentication in
                guard let self = self else { return }
                
                // bind objectID
                self.activeMastodonAuthenticationObjectID.value = authentication?.objectID
                
                self.isAvatarButtonDataReady = authentication != nil
            }
            .store(in: &disposeBag)
    }
    
}

extension SidebarViewModel {
    enum Section: Int, Hashable, CaseIterable {
        case main
        case secondary
    }
    
    enum Item: Hashable {
        case tab(MainTabBarController.Tab)
        case setting
        case compose
    }
    
}

extension SidebarViewModel {
    func setupDiffableDataSource(
        collectionView: UICollectionView,
        secondaryCollectionView: UICollectionView
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
            cell.item = SidebarListContentView.Item(
                isActive: false,
                title: item.title,
                image: item.image,
                activeImage: item.selectedImage,
                imageURL: imageURL
            )
            cell.setNeedsUpdateConfiguration()
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.title
            
            self.$currentTab
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] currentTab in
                    guard let cell = cell else { return }
                    cell.item?.isActive = currentTab == item
                    cell.setNeedsUpdateConfiguration()
                }
                .store(in: &cell.disposeBag)
            
            switch item {
            case .notification:
                Publishers.CombineLatest3(
                    self.context.authenticationService.activeMastodonAuthentication,
                    self.context.notificationService.unreadNotificationCountDidUpdate,
                    self.$currentTab
                )
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] authentication, _, currentTab in
                    guard let cell = cell else { return }
                    let hasUnreadPushNotification: Bool = authentication.flatMap { authentication in
                        let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: authentication.userAccessToken)
                        return count > 0
                    } ?? false
                    
                    let image: UIImage = {
                        if currentTab == .notification {
                            return hasUnreadPushNotification ? Asset.ObjectsAndTools.bellBadgeFill.image.withRenderingMode(.alwaysTemplate) : Asset.ObjectsAndTools.bellFill.image.withRenderingMode(.alwaysTemplate)
                        } else {
                            return hasUnreadPushNotification ? Asset.ObjectsAndTools.bellBadge.image.withRenderingMode(.alwaysTemplate) : Asset.ObjectsAndTools.bell.image.withRenderingMode(.alwaysTemplate)
                        }
                    }()
                    cell.item?.image = image
                    cell.item?.activeImage = image
                    cell.setNeedsUpdateConfiguration()
                }
                .store(in: &cell.disposeBag)
            case .me:
                guard let authentication = self.context.authenticationService.activeMastodonAuthentication.value else { break }
                let currentUserDisplayName = authentication.user.displayNameWithFallback
                cell.accessibilityHint = L10n.Scene.AccountList.tabBarHint(currentUserDisplayName)
            default:
                break
            }
        }
        
        let cellRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, SidebarListContentView.Item> { [weak self] cell, indexPath, item in
            guard let _ = self else { return }
            cell.item = item
            cell.setNeedsUpdateConfiguration()
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.title
        }
        
        // header
        let headerRegistration = UICollectionView.SupplementaryRegistration<SidebarListHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            // do nothing
        }
        
        let _diffableDataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tab(let tab):
                return collectionView.dequeueConfiguredReusableCell(using: tabCellRegistration, for: indexPath, item: tab)
            case .setting:
                let item = SidebarListContentView.Item(
                    isActive: false,
                    title: L10n.Common.Controls.Actions.settings,
                    image: Asset.ObjectsAndTools.gear.image.withRenderingMode(.alwaysTemplate),
                    activeImage: Asset.ObjectsAndTools.gear.image.withRenderingMode(.alwaysTemplate),
                    imageURL: nil
                )
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            case .compose:
                let item = SidebarListContentView.Item(
                    isActive: false,
                    title: L10n.Common.Controls.Actions.compose,
                    image: Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate),
                    activeImage: Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate),
                    imageURL: nil
                )
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
        _diffableDataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            default:
                assertionFailure()
                return UICollectionReusableView()
            }
        }
        diffableDataSource = _diffableDataSource
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let items: [Item] = [
            .tab(.home),
            .tab(.search),
            .tab(.notification),
            .tab(.me),
            .setting,
        ]
        sectionSnapshot.append(items, to: nil)
        // animatingDifferences must to be `true`
        // otherwise the UI layout will infinity loop
        _diffableDataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true) { [weak self] in
            guard let self = self else { return }
            self.isSidebarDataSourceReady = true
        }
    
        // secondary
        let _secondaryDiffableDataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: secondaryCollectionView) { collectionView, indexPath, item in
            guard case .compose = item else {
                assertionFailure()
                return UICollectionViewCell()
            }
            
            let item = SidebarListContentView.Item(
                isActive: false,
                title: L10n.Common.Controls.Actions.compose,
                image: Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate),
                activeImage: Asset.ObjectsAndTools.squareAndPencil.image.withRenderingMode(.alwaysTemplate),
                imageURL: nil
            )
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        secondaryDiffableDataSource = _secondaryDiffableDataSource
        
        var secondarySnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        secondarySnapshot.appendSections([.secondary])

        var secondarySectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let secondarySectionItems: [Item] = [
            .compose,
        ]
        secondarySectionSnapshot.append(secondarySectionItems, to: nil)
        _secondaryDiffableDataSource.apply(secondarySectionSnapshot, to: .secondary)
    }

}
