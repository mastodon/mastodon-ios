//
//  UserProvider.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

protocol UserProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    // async
    func mastodonUser() -> Future<MastodonUser?, Never>
}
