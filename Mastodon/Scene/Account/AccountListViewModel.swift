//
//  AccountListViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonMeta
import MastodonCore
import MastodonUI

final class AccountListViewModel: NSObject {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let mastodonAuthenticationFetchedResultsController: NSFetchedResultsController<MastodonAuthentication>

    // output
    @Published var authentications: [ManagedObjectRecord<MastodonAuthentication>] = []
    @Published var items: [Item] = []
    
    let dataSourceDidUpdate = PassthroughSubject<Void, Never>()
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>!

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.mastodonAuthenticationFetchedResultsController = {
            let fetchRequest = MastodonAuthentication.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            return controller
        }()
        super.init()
        // end init
        
        mastodonAuthenticationFetchedResultsController.delegate = self
        do {
            try mastodonAuthenticationFetchedResultsController.performFetch()
            authentications = mastodonAuthenticationFetchedResultsController.fetchedObjects?.compactMap { $0.asRecord } ?? []
        } catch {
            assertionFailure(error.localizedDescription)
        }

        $authentications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authentications in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                let authenticationItems: [Item] = authentications.map {
                    Item.authentication(record: $0)
                }
                snapshot.appendItems(authenticationItems, toSection: .main)
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
        case authentication(record: ManagedObjectRecord<MastodonAuthentication>)
        case addAccount
    }

    func setupDiffableDataSource(
        tableView: UITableView,
        managedObjectContext: NSManagedObjectContext
    ) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .authentication(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AccountListTableViewCell.self), for: indexPath) as! AccountListTableViewCell
                if let authentication = record.object(in: managedObjectContext),
                   let activeAuthentication = self.authContext.mastodonAuthenticationBox.authenticationRecord.object(in: managedObjectContext)
                {
                    AccountListViewModel.configure(
                        cell: cell,
                        authentication: authentication,
                        activeAuthentication: activeAuthentication
                    )
                }
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
        activeAuthentication: MastodonAuthentication
    ) {
        let user = authentication.user
        
        // avatar
        cell.avatarButton.avatarImageView.configure(
            configuration: .init(url: user.avatarImageURL())
        )

        // name
        do {
            let content = MastodonContent(content: user.displayNameWithFallback, emojis: user.emojis.asDictionary)
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
        let isActive = activeAuthentication.userID == authentication.userID
        cell.tintColor = .label
        cell.checkmarkImageView.isHidden = !isActive
        if isActive {
            cell.accessibilityTraits.insert(.selected)
        } else {
            cell.accessibilityTraits.remove(.selected)
        }
        
        cell.accessibilityLabel = [
            cell.nameLabel.text,
            cell.usernameLabel.text,
            cell.badgeButton.accessibilityLabel
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AccountListViewModel: NSFetchedResultsControllerDelegate {
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard controller === mastodonAuthenticationFetchedResultsController else {
            assertionFailure()
            return
        }
        
        authentications = mastodonAuthenticationFetchedResultsController.fetchedObjects?.compactMap { $0.asRecord } ?? []
    }
    
}
