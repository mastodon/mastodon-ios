//
//  FavoritedByViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import GameplayKit
import Combine
import MastodonCore
import MastodonLocalization
import MastodonUI
import CoreDataStack

final class FavoritedByViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserListViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    
}

extension FavoritedByViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.FavoritedBy.title
        
        view.backgroundColor = .secondarySystemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            userTableViewCellDelegate: self
        )

        viewModel.stateMachine.enter(UserListViewModel.State.Loading.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - AuthContextProvider
extension FavoritedByViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension FavoritedByViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:FavoritedByViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    // sourcery:end
}

// MARK: - UserTableViewCellDelegate
extension FavoritedByViewController: UserTableViewCellDelegate {}

//MARK: - UIScrollViewDelegate

extension FavoritedByViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Self.scrollViewDidScrollToEnd(scrollView) {
            viewModel.stateMachine.enter(UserListViewModel.State.Loading.self)
        }
    }
}
