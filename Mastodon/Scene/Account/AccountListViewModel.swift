//
//  AccountListViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//

#if DEBUG
import UIKit
import Combine
import CoreData
import CoreDataStack

final class AccountListViewModel {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext

    // output
    let authentications = CurrentValueSubject<[Item], Never>([])
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>!

    init(context: AppContext) {
        self.context = context

        context.authenticationService.mastodonAuthentications
            .map { authentications in
                return authentications.map {
                    Item.authentication(objectID: $0.objectID)
                }
            }
            .assign(to: \.value, on: authentications)
            .store(in: &disposeBag)

        authentications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authentications in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(authentications, toSection: .main)

                diffableDataSource.apply(snapshot)
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
    }

    func setupDiffableDataSource(
        tableView: UITableView,
        managedObjectContext: NSManagedObjectContext
    ) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .authentication(let objectID):
                let authentication = managedObjectContext.object(with: objectID) as! MastodonAuthentication
                let user = authentication.user
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AccountListTableViewCell.self), for: indexPath) as! AccountListTableViewCell
                cell.textLabel?.text = user.acctWithDomain
                return cell
            }
        }
    }
}

#endif
