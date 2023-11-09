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
    var context: AppContext!
    var coordinator: SceneCoordinator!
    let authContext: AuthContext

    var disposeBag = Set<AnyCancellable>()
    var viewModel: FollowedTagsViewModel
    
    let titleView = DoubleTitleLabelNavigationBarTitleView()
    let tableView: UITableView

    init(appContext: AppContext, sceneCoordinator: SceneCoordinator, authContext: AuthContext, viewModel: FollowedTagsViewModel) {
        self.context = appContext
        self.coordinator = sceneCoordinator
        self.authContext = authContext
        self.viewModel = viewModel

        tableView = UITableView()
        tableView.register(FollowedTagsTableViewCell.self, forCellReuseIdentifier: FollowedTagsTableViewCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        super.init(nibName: nil, bundle: nil)

        let title = L10n.Scene.FollowedTags.title
        self.title = title
        titleView.update(title: title, subtitle: nil)

        navigationItem.titleView = titleView

        view.backgroundColor = .secondarySystemBackground

        view.addSubview(tableView)
        tableView.pinToParent()

        tableView.delegate = self
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setupTableView(tableView)
    }
}

extension FollowedTagsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let object = viewModel.followedTags[indexPath.row]

        let hashtagTimelineViewModel = HashtagTimelineViewModel(
            context: self.context,
            authContext: self.authContext,
            hashtag: object.name
        )

        _ = self.coordinator.present(
            scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
            from: self,
            transition: .show
        )

    }
}
