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
    var viewModel: FollowedTagsViewModel!
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(FollowedTagsTableViewCell.self, forCellReuseIdentifier: String(describing: FollowedTagsTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension FollowedTagsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _title = L10n.Scene.FollowedTags.title
        title = _title
        titleView.update(title: _title, subtitle: nil)

        navigationItem.titleView = titleView
        
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        viewModel.setupTableView(tableView)
        
        viewModel.presentHashtagTimeline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hashtagTimelineViewModel in
                guard let self = self else { return }
                _ = self.coordinator.present(
                    scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
                    from: self,
                    transition: .show
                )
            }
            .store(in: &disposeBag)
    }
}
