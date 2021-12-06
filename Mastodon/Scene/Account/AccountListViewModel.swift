//
//  AccountListViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonMeta

final class AccountListViewModel {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext

    // output
    let authentications = CurrentValueSubject<[Item], Never>([])
    let activeMastodonUserObjectID = CurrentValueSubject<NSManagedObjectID?, Never>(nil)
    let dataSourceDidUpdate = PassthroughSubject<Void, Never>()
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>!

    init(context: AppContext) {
        self.context = context

        Publishers.CombineLatest(
            context.authenticationService.mastodonAuthentications,
            context.authenticationService.activeMastodonAuthentication
        )
        .sink { [weak self] authentications, activeAuthentication in
            guard let self = self else { return }
            var items: [Item] = []
            var activeMastodonUserObjectID: NSManagedObjectID?
            for authentication in authentications {
                let item = Item.authentication(objectID: authentication.objectID)
                items.append(item)
                if authentication === activeAuthentication {
                    activeMastodonUserObjectID = authentication.user.objectID
                }
            }
            self.authentications.value = items
            self.activeMastodonUserObjectID.value = activeMastodonUserObjectID
        }
        .store(in: &disposeBag)

        authentications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authentications in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(authentications, toSection: .main)
                snapshot.appendItems([.addAccount], toSection: .main)

                diffableDataSource.apply(snapshot) {
                    self.dataSourceDidUpdate.send()
                }
            }
            .store(in: &disposeBag)
    }

}

extension AccountListViewModel {
    enum Section: Hashable {
        case main
    }

    enum Item: Hashable {
        case authentication(objectID: NSManagedObjectID)
        case addAccount
    }

    func setupDiffableDataSource(
        tableView: UITableView,
        managedObjectContext: NSManagedObjectContext
    ) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .authentication(let objectID):
                let authentication = managedObjectContext.object(with: objectID) as! MastodonAuthentication
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AccountListTableViewCell.self), for: indexPath) as! AccountListTableViewCell
                AccountListViewModel.configure(
                    cell: cell,
                    authentication: authentication,
                    activeMastodonUserObjectID: self.activeMastodonUserObjectID.eraseToAnyPublisher()
                )
                return cell
            case .addAccount:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddAccountTableViewCell.self), for: indexPath) as! AddAccountTableViewCell
                return cell
            }
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
    }

    static func configure(
        cell: AccountListTableViewCell,
        authentication: MastodonAuthentication,
        activeMastodonUserObjectID: AnyPublisher<NSManagedObjectID?, Never>
    ) {
        let user = authentication.user
        
        // avatar
        cell.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: user.avatarImageURL()))

        // name
        do {
            let content = MastodonContent(content: user.displayNameWithFallback, emojis: user.emojiMeta)
            let metaContent = try MastodonMetaContent.convert(document: content)
            cell.nameLabel.configure(content: metaContent)
        } catch {
            assertionFailure()
            cell.nameLabel.configure(content: PlaintextMetaContent(string: user.displayNameWithFallback))
        }

        // username
        let usernameMetaContent = PlaintextMetaContent(string: "@" + user.acctWithDomain)
        cell.usernameLabel.configure(content: usernameMetaContent)
        
        // badge
        let accessToken = authentication.userAccessToken
        let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
        cell.badgeButton.setBadge(number: count)
        
        // checkmark
        activeMastodonUserObjectID
            .receive(on: DispatchQueue.main)
            .sink { objectID in
                let isCurrentUser =  user.objectID == objectID
                cell.tintColor = .label
                cell.checkmarkImageView.isHidden = !isCurrentUser
                if isCurrentUser {
                    cell.accessibilityTraits.insert(.selected)
                } else {
                    cell.accessibilityTraits.remove(.selected)
                }
            }
            .store(in: &cell.disposeBag)
        
        cell.accessibilityLabel = [
            cell.nameLabel.text,
            cell.usernameLabel.text,
            cell.badgeButton.accessibilityLabel
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}
