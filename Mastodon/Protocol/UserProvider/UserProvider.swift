//
//  UserProvider.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import Combine
import CoreData
import CoreDataStack
import UIKit

protocol UserProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    // async
    func mastodonUser() -> Future<MastodonUser?, Never>

    func mastodonUser(for cell: UITableViewCell?, indexPath: IndexPath?) -> Future<MastodonUser?, Never>
}

extension UserProvider where Self: StatusProvider {
    func mastodonUser(for cell: UITableViewCell?, indexPath: IndexPath?) -> Future<MastodonUser?, Never> {
        Future { [weak self] promise in
            guard let self = self else { return }
            self.status(for: cell, indexPath: indexPath)
                .sink { status in
                    promise(.success(status?.authorForUserProvider))
                }
                .store(in: &self.disposeBag)
        }
    }

    func mastodonUser() -> Future<MastodonUser?, Never> {
        Future { promise in
            promise(.success(nil))
        }
    }
}
