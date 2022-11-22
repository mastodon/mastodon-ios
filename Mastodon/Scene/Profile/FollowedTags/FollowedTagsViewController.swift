//
//  FollowedTagsViewController.swift
//  Mastodon
//
//  Created by Marcus Kida on 22.11.22.
//

import os
import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class FollowedTagsViewController: UIViewController, NeedsDependency {
    let logger = Logger(subsystem: String(describing: FollowedTagsViewController.self), category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: BookmarkViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(HashtagTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}
