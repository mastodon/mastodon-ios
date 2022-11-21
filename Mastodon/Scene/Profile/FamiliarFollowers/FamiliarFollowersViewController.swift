//
//  FamiliarFollowersViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import os.log
import UIKit
import Combine
import MastodonCore
import MastodonLocalization

final class FamiliarFollowersViewController: UIViewController, NeedsDependency {

    let logger = Logger(subsystem: "FamiliarFollowersViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: FamiliarFollowersViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension FamiliarFollowersViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Familiarfollowers.title
        
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            userTableViewCellDelegate: self
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - AuthContextProvider
extension FamiliarFollowersViewController: AuthContextProvider {
    var authContext: AuthContext {
        viewModel.authContext
    }
}

// MARK: - UITableViewDelegate
extension FamiliarFollowersViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:FamiliarFollowersViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    // sourcery:end
}

// MARK: - UserTableViewCellDelegate
extension FamiliarFollowersViewController: UserTableViewCellDelegate { }
