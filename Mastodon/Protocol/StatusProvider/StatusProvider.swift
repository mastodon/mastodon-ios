//
//  StatusProvider.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import UIKit
import Combine
import CoreDataStack

protocol StatusProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    func toot() -> Future<Toot?, Never>
    func toot(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Toot?, Never>
    func toot(for cell: UICollectionViewCell) -> Future<Toot?, Never>
}
