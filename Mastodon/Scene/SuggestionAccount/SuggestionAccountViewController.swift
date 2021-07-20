//
//  SuggestionAccountViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import OSLog
import UIKit

class SuggestionAccountViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()

    var viewModel: SuggestionAccountViewModel!

    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(SuggestionAccountTableViewCell.self, forCellReuseIdentifier: String(describing: SuggestionAccountTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    lazy var tableHeader: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeService.shared.currentTheme.value.systemGroupedBackgroundColor
        view.frame = CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 156))
        return view
    }()

    let followExplainLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Scene.SuggestionAccount.followExplain
        label.textColor = Asset.Colors.Label.primary.color
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.numberOfLines = 0
        return label
    }()

    let selectedCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let view = ControlContainableCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.register(SuggestionAccountCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SuggestionAccountCollectionViewCell.self))
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.layer.masksToBounds = false
        return view
    }()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", (#file as NSString).lastPathComponent, #line, #function)
    }
}

extension SuggestionAccountViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        title = L10n.Scene.SuggestionAccount.title
        navigationItem.rightBarButtonItem
            = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                              target: self,
                              action: #selector(SuggestionAccountViewController.doneButtonDidClick(_:)))

        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        viewModel.diffableDataSource = RecommendAccountSection.tableViewDiffableDataSource(
            for: tableView,
            managedObjectContext: context.managedObjectContext,
            viewModel: viewModel,
            delegate: self
        )

        viewModel.collectionDiffableDataSource = SelectedAccountSection.collectionViewDiffableDataSource(for: selectedCollectionView, managedObjectContext: context.managedObjectContext)

        viewModel.accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                guard let self = self else { return }
                self.setupHeader(accounts: accounts)
            }
            .store(in: &disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
        viewModel.checkAccountsFollowState()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let avatarImageViewHeight: Double = 56
        let avatarImageViewCount = Int(floor((Double(view.frame.width) - 20) / (avatarImageViewHeight + 15)))
        viewModel.headerPlaceholderCount.value = avatarImageViewCount
    }

    func setupHeader(accounts: [NSManagedObjectID]) {
        if accounts.isEmpty {
            return
        }
        followExplainLabel.translatesAutoresizingMaskIntoConstraints = false
        tableHeader.addSubview(followExplainLabel)
        NSLayoutConstraint.activate([
            followExplainLabel.topAnchor.constraint(equalTo: tableHeader.topAnchor, constant: 20),
            followExplainLabel.leadingAnchor.constraint(equalTo: tableHeader.leadingAnchor, constant: 20),
            tableHeader.trailingAnchor.constraint(equalTo: followExplainLabel.trailingAnchor, constant: 20),
        ])

        selectedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        tableHeader.addSubview(selectedCollectionView)
        NSLayoutConstraint.activate([
            selectedCollectionView.frameLayoutGuide.topAnchor.constraint(equalTo: followExplainLabel.topAnchor, constant: 20),
            selectedCollectionView.frameLayoutGuide.leadingAnchor.constraint(equalTo: tableHeader.leadingAnchor, constant: 20),
            selectedCollectionView.frameLayoutGuide.trailingAnchor.constraint(equalTo: tableHeader.trailingAnchor),
            selectedCollectionView.frameLayoutGuide.bottomAnchor.constraint(equalTo: tableHeader.bottomAnchor),
        ])
        selectedCollectionView.delegate = self

        tableView.tableHeaderView = tableHeader
    }

    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemBackgroundColor
        tableHeader.backgroundColor = theme.systemGroupedBackgroundColor
    }
}

extension SuggestionAccountViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        15
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 56, height: 56)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.collectionDiffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .accountObjectID(let accountObjectID):
            let mastodonUser = context.managedObjectContext.object(with: accountObjectID) as! MastodonUser
            let viewModel = ProfileViewModel(context: context, optionalMastodonUser: mastodonUser)
            DispatchQueue.main.async {
                self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
            }
        default:
            break
        }
    }
}

extension SuggestionAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let objectID = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        let mastodonUser = context.managedObjectContext.object(with: objectID) as! MastodonUser
        let viewModel = ProfileViewModel(context: context, optionalMastodonUser: mastodonUser)
        DispatchQueue.main.async {
            self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
        }
    }
}

extension SuggestionAccountViewController: SuggestionAccountTableViewCellDelegate {
    func accountButtonPressed(objectID: NSManagedObjectID, cell: SuggestionAccountTableViewCell) {
        let selected = !viewModel.selectedAccounts.value.contains(objectID)
        cell.startAnimating()
        viewModel.followAction(objectID: objectID)?
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                cell.stopAnimating()
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: follow failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                case .finished:
                    var selectedAccounts = self.viewModel.selectedAccounts.value
                    if selected {
                        selectedAccounts.append(objectID)
                    } else {
                        selectedAccounts.removeAll { $0 == objectID }
                    }
                    cell.button.isSelected = selected
                    self.viewModel.selectedAccounts.value = selectedAccounts
                }
            }, receiveValue: { _ in
            })
            .store(in: &disposeBag)
    }
}

extension SuggestionAccountViewController {
    @objc func doneButtonDidClick(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        if viewModel.selectedAccounts.value.count > 0 {
            viewModel.delegate?.homeTimelineNeedRefresh.send()
        }
    }
}
