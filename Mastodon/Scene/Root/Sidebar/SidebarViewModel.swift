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
import MastodonCore
import MastodonLocalization

@MainActor
final class SidebarViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let authenticationBox: MastodonAuthenticationBox?
    @Published private var isSidebarDataSourceReady = false
    @Published private var isAvatarButtonDataReady = false
    @Published var currentTab: Tab = .home

    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>?
    var secondaryDiffableDataSource: UICollectionViewDiffableDataSource<Section, Item>?
    @Published private(set) var isReadyForWizardAvatarButton = false
    
    private let chevronImage = UIImage.chevronUpChevronDown?.withConfiguration(
        UIImage.SymbolConfiguration(weight: .bold)
    )

    init(authenticationBox: MastodonAuthenticationBox?) {
        self.authenticationBox = authenticationBox
        
        Publishers.CombineLatest(
            $isSidebarDataSourceReady,
            $isAvatarButtonDataReady
        )
        .map { $0 && $1 }
        .assign(to: &$isReadyForWizardAvatarButton)
        
        self.isAvatarButtonDataReady = authenticationBox != nil
    }
    
}

extension SidebarViewModel {
    enum Section: Int, Hashable, CaseIterable {
        case main
        case secondary
    }
    
    enum Item: Hashable {
        case tab(Tab)
        case setting
        case compose
    }
    
}

extension SidebarViewModel {
    func setupDiffableDataSource(
        collectionView: UICollectionView,
        secondaryCollectionView: UICollectionView
    ) {
        let tabCellRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, Tab> { [weak self] cell, indexPath, item in
            guard let self else { return }

            let imageURL: URL?
            switch item {
            case .me:
                let account = self.authenticationBox?.authentication.cachedAccount()
                imageURL = account?.avatarImageURL()
            case .home, .search, .compose, .notifications:
                // no custom avatar for other tabs
                imageURL = nil
            }

            cell.item = SidebarListContentView.Item(
                isActive: false,
                accessoryImage: item == .me ? self.chevronImage : nil,
                title: item.title,
                image: item.image,
                activeImage: item.selectedImage.withTintColor(Asset.Colors.Brand.blurple.color, renderingMode: .alwaysOriginal),
                imageURL: imageURL
            )
            cell.setNeedsUpdateConfiguration()
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.title
            cell.accessibilityTraits.insert(.button)
            
            self.$currentTab
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] currentTab in
                    guard let cell = cell else { return }
                    cell.item?.isActive = currentTab == item
                    cell.setNeedsUpdateConfiguration()
                }
                .store(in: &cell.disposeBag)
            
            switch item {
                case .notifications:
                    Publishers.CombineLatest(
                        NotificationService.shared.unreadNotificationCountDidUpdate,
                        self.$currentTab
                    )
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] authentication, currentTab in
                        guard let cell = cell else { return }

                        let hasUnreadPushNotification: Bool = {
                            guard let accessToken = self.authenticationBox?.userAuthorization.accessToken else { return false }
                            let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
                            return count > 0
                        }()

                        let image: UIImage
                        if hasUnreadPushNotification {
                            let imageConfiguration = UIImage.SymbolConfiguration(paletteColors: [.red, SystemTheme.tabBarItemNormalIconColor])
                            image = UIImage(systemName: "bell.badge", withConfiguration: imageConfiguration)!
                        } else {
                            image = Tab.notifications.image
                        }
                        cell.item?.image = image
                        cell.item?.activeImage = image.withTintColor(Asset.Colors.Brand.blurple.color, renderingMode: .alwaysOriginal)
                        cell.setNeedsUpdateConfiguration()
                    }
                    .store(in: &cell.disposeBag)
                case .me:
                    guard let account = self.authenticationBox?.authentication.cachedAccount() else { return }

                    let currentUserDisplayName = account.displayNameWithFallback
                    cell.accessibilityHint = L10n.Scene.AccountList.tabBarHint(currentUserDisplayName)
                case .compose, .home, .search:
                    break
            }
        }
        
        let cellRegistration = UICollectionView.CellRegistration<SidebarListCollectionViewCell, SidebarListContentView.Item> { [weak self] cell, indexPath, item in
            guard let _ = self else { return }
            cell.item = item
            cell.setNeedsUpdateConfiguration()
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.title
            cell.accessibilityTraits.insert(.button)
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
                    accessoryImage: self.currentTab == .me ? self.chevronImage : nil,
                    title: L10n.Common.Controls.Actions.compose,
                    image: UIImage(systemName: "square.and.pencil")!.withRenderingMode(.alwaysTemplate),
                    activeImage: UIImage(systemName: "square.and.pencil")!.withRenderingMode(.alwaysTemplate),
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
            .tab(.notifications),
            .tab(.me),
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
                image: UIImage(systemName: "square.and.pencil")!.withRenderingMode(.alwaysTemplate),
                activeImage: UIImage(systemName: "square.and.pencil")!.withRenderingMode(.alwaysTemplate),
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
