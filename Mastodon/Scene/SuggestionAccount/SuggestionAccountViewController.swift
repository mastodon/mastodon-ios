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
import MastodonAsset
import MastodonLocalization

class SuggestionAccountViewController: UIViewController, NeedsDependency {
    
    static let collectionViewHeight: CGFloat = 24 + 64 + 24
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SuggestionAccountViewModel!
    
    private static func createCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(64), heightDimension: .absolute(64))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 0, bottom: 24, trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsetsReference = .readableContent
        section.interGroupSpacing = 16

        return UICollectionViewCompositionalLayout(section: section)
    }
    
    let collectionView: UICollectionView = {
        let collectionViewLayout = SuggestionAccountViewController.createCollectionViewLayout()
        let view = ControlContainableCollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewLayout
        )
        view.register(SuggestionAccountCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SuggestionAccountCollectionViewCell.self))
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.layer.masksToBounds = false
        return view
    }()

    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(SuggestionAccountTableViewCell.self, forCellReuseIdentifier: String(describing: SuggestionAccountTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return tableView
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.done,
            target: self,
            action: #selector(SuggestionAccountViewController.doneButtonDidClick(_:))
        )
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: SuggestionAccountViewController.collectionViewHeight),
        ])
        defer { view.bringSubviewToFront(collectionView) }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView
        )
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            suggestionAccountTableViewCellDelegate: self
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }

    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemBackgroundColor
        collectionView.backgroundColor = theme.systemGroupedBackgroundColor
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SuggestionAccountViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let diffableDataSource = viewModel.collectionDiffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        switch item {
//        case .accountObjectID(let accountObjectID):
//            let mastodonUser = context.managedObjectContext.object(with: accountObjectID) as! MastodonUser
//            let viewModel = ProfileViewModel(context: context, optionalMastodonUser: mastodonUser)
//            DispatchQueue.main.async {
//                self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
//            }
//        default:
//            break
//        }
    }
}

// MARK: - UITableViewDelegate
extension SuggestionAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewDiffableDataSource = viewModel.tableViewDiffableDataSource else { return }
        guard let item = tableViewDiffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .account(let record):
            guard let account = record.object(in: context.managedObjectContext) else { return }
            let cachedProfileViewModel = CachedProfileViewModel(context: context, mastodonUser: account)
            coordinator.present(
                scene: .profile(viewModel: cachedProfileViewModel),
                from: self,
                transition: .show
            )
        }
    }
}

extension SuggestionAccountViewController: SuggestionAccountTableViewCellDelegate {
    func accountButtonPressed(objectID: NSManagedObjectID, cell: SuggestionAccountTableViewCell) {
//        let selected = !viewModel.selectedAccounts.value.contains(objectID)
//        cell.startAnimating()
//        viewModel.followAction(objectID: objectID)?
//            .sink(receiveCompletion: { [weak self] completion in
//                guard let self = self else { return }
//                cell.stopAnimating()
//                switch completion {
//                case .failure(let error):
//                    os_log("%{public}s[%{public}ld], %{public}s: follow failed. %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
//                case .finished:
//                    var selectedAccounts = self.viewModel.selectedAccounts.value
//                    if selected {
//                        selectedAccounts.append(objectID)
//                    } else {
//                        selectedAccounts.removeAll { $0 == objectID }
//                    }
//                    cell.button.isSelected = selected
//                    self.viewModel.selectedAccounts.value = selectedAccounts
//                }
//            }, receiveValue: { _ in
//            })
//            .store(in: &disposeBag)
    }
}

extension SuggestionAccountViewController {
    @objc func doneButtonDidClick(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
//        if viewModel.selectedAccounts.value.count > 0 {
//            viewModel.delegate?.homeTimelineNeedRefresh.send()
//        }
    }
}
