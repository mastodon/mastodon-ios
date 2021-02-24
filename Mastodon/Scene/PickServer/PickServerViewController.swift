//
//  PickServerViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import Combine

final class PickServerViewController: UIViewController, NeedsDependency {
    
    private var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: PickServerViewModel!
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 34)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.ServerPicker.title
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(PickServerTitleCell.self, forCellReuseIdentifier: String(describing: PickServerTitleCell.self))
        tableView.register(PickServerCategoriesCell.self, forCellReuseIdentifier: String(describing: PickServerCategoriesCell.self))
        tableView.register(PickServerSearchCell.self, forCellReuseIdentifier: String(describing: PickServerSearchCell.self))
        tableView.register(PickServerCell.self, forCellReuseIdentifier: String(describing: PickServerCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    let nextStepButton: PrimaryActionButton = {
        let button = PrimaryActionButton(type: .system)
        button.setTitle(L10n.Button.signUp, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
}

extension PickServerViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        
        view.addSubview(nextStepButton)
        NSLayoutConstraint.activate([
            nextStepButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 12),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: nextStepButton.trailingAnchor, constant: 12),
            view.bottomAnchor.constraint(equalTo: nextStepButton.bottomAnchor, constant: 34),
        ])
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextStepButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 7)
        ])
        
        switch viewModel.mode {
        case .SignIn:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.signIn, for: .normal)
        case .SignUp:
            nextStepButton.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
        }
        
        viewModel.tableView = tableView
        tableView.delegate = viewModel
        tableView.dataSource = viewModel
        
        viewModel.searchedServers
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("22")
            } receiveValue: { [weak self] servers in
                self?.tableView.reloadSections(IndexSet(integer: 3), with: .automatic)
            }
            .store(in: &disposeBag)

        
        viewModel.fetchAllServers()
    }
}
