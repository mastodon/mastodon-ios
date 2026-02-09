//
//  MastodonPickServerViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import Combine
import GameController
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI
import MastodonSDK

final class MastodonPickServerViewController: UIViewController {
    
    var coordinator: SceneCoordinator!
    
    init(coordinator: SceneCoordinator, viewModel: MastodonPickServerViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()
    private var tableViewObservation: NSKeyValueObservation?
    
    let viewModel: MastodonPickServerViewModel
    
    private var expandServerDomainSet = Set<String>()
    
    private let emptyStateView = PickServerEmptyStateView()
    private var emptyStateViewLeadingLayoutConstraint: NSLayoutConstraint!
    private var emptyStateViewTrailingLayoutConstraint: NSLayoutConstraint!
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionHeaderTopPadding = .leastNonzeroMagnitude
        return tableView
    }()

    let onboardingNextView: OnboardingNextView = {
        let onboardingNextView = OnboardingNextView()
        onboardingNextView.translatesAutoresizingMaskIntoConstraints = false
        onboardingNextView.backgroundColor = UIColor.secondarySystemBackground
        return onboardingNextView
    }()

    let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = L10n.Scene.ServerPicker.Search.placeholder
        return searchController
    }()
}

extension MastodonPickServerViewController {    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        defer {
            setupNavigationBarBackgroundView()
            setupNavigationBarAppearance()
        }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])
        
        view.addSubview(onboardingNextView)

        NSLayoutConstraint.activate([
            onboardingNextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingNextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: onboardingNextView.bottomAnchor),
        ])
        
        onboardingNextView
            .observe(\.bounds, options: [.initial, .new]) { [weak self] _, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let inset = self.onboardingNextView.frame.height
                    self.viewModel.additionalTableViewInsets.bottom = inset
                }
            }
            .store(in: &observations)

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        emptyStateViewLeadingLayoutConstraint = emptyStateView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor)
        emptyStateViewTrailingLayoutConstraint = tableView.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateViewLeadingLayoutConstraint,
            emptyStateViewTrailingLayoutConstraint,
            onboardingNextView.topAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: 21),
        ])
        view.sendSubviewToBack(emptyStateView)

        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            pickServerServerSectionTableHeaderViewDelegate: self
        )
        
        KeyboardResponderService
            .configure(
                scrollView: tableView,
                layoutNeedsUpdate: viewModel.viewDidAppear.eraseToAnyPublisher(),
                additionalSafeAreaInsets: viewModel.$additionalTableViewInsets.eraseToAnyPublisher()
            )
            .store(in: &disposeBag)
        
        viewModel.scrollToTop
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.scroll(to: .top, animated: false)
            }
            .store(in: &disposeBag)



        viewModel.emptyStateViewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .none:
                    UIView.animate(withDuration: 0.3) {
                        self.emptyStateView.alpha = 0
                    }
                case .loading:
                    self.emptyStateView.alpha = 1
                    self.emptyStateView.networkIndicatorImageView.isHidden = true
                    self.emptyStateView.activityIndicatorView.startAnimating()
                    self.emptyStateView.infoLabel.isHidden = false
                    self.emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.findingServers
                    self.emptyStateView.infoLabel.textAlignment = self.traitCollection.layoutDirection == .rightToLeft ? .right : .left
                case .badNetwork:
                    self.emptyStateView.alpha = 1
                    self.emptyStateView.networkIndicatorImageView.isHidden = false
                    self.emptyStateView.activityIndicatorView.stopAnimating()
                    self.emptyStateView.infoLabel.isHidden = false
                    self.emptyStateView.infoLabel.text = L10n.Scene.ServerPicker.EmptyState.badNetwork
                    self.emptyStateView.infoLabel.textAlignment = .center
                }
            }
            .store(in: &disposeBag)
        
        onboardingNextView.nextButton.addTarget(self, action: #selector(MastodonPickServerViewController.next(_:)), for: .touchUpInside)

        viewModel.allLanguages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let snapshot = self?.viewModel.serverSectionHeaderView.diffableDataSource?.snapshot() else { return }

                self?.viewModel.serverSectionHeaderView.diffableDataSource?.applySnapshotUsingReloadData(snapshot) {
                    guard let viewModel = self?.viewModel else { return }
                    guard let indexPath = viewModel.serverSectionHeaderView.diffableDataSource?.indexPath(for: .category(category: .init(category: Mastodon.Entity.Category.Kind.general.rawValue, serversCount: 0))) else { return }

                    viewModel.serverSectionHeaderView.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .right)

                    let firstIndex = IndexPath(item: 0, section: 0)
                    viewModel.serverSectionHeaderView.collectionView.scrollToItem(at: firstIndex, at: .left, animated: false)
                }
            }
            .store(in: &disposeBag)

        title = L10n.Scene.ServerPicker.title

        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onboardingNextView.stopLoading()
        viewModel.viewWillAppear.send()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
        viewModel.viewDidAppear.send()
    }
}

extension MastodonPickServerViewController {

    @objc private func next(_ sender: UIButton) {

        let server: Mastodon.Entity.Server

        if let selectedServer = viewModel.selectedServer.value {
            server = selectedServer
        } else if let randomServer = viewModel.chooseRandomServer() {
            server = randomServer
        } else {
            return
        }

        Task {
            await tryToJoin(server: server)
        }
        
    }
    
    private func tryToJoin(server: Mastodon.Entity.Server) async {
        self.onboardingNextView.showLoading()
        do {
            try await viewModel.joinServer(server)
        } catch let error {
            viewModel.displayError(error)
        }
        self.onboardingNextView.stopLoading()
    }
}

// MARK: - UITableViewDelegate
extension MastodonPickServerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        guard case .server = item else { return nil }
        
        if tableView.indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: false)
            viewModel.selectedServer.send(nil)
            return nil
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .server(server, _) = item else { return }
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        viewModel.selectedServer.send(server)
        
        // Briefly highlight selected cell
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        cell.backgroundColor = Asset.Colors.selectionHighlight.color
        UIView.animate(withDuration: 0.3, animations: {
            cell.backgroundColor = .none
        })
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        viewModel.selectedServer.send(nil)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        let snapshot = diffableDataSource.snapshot()
        guard section < snapshot.numberOfSections else { return nil }
        let section = snapshot.sectionIdentifiers[section]
        
        switch section {
        case .servers:
            return viewModel.serverSectionHeaderView
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource else { return .leastNonzeroMagnitude }
        let snapshot = diffableDataSource.snapshot()
        guard section < snapshot.numberOfSections else { return .leastNonzeroMagnitude }
        let section = snapshot.sectionIdentifiers[section]
        
        switch section {
        case .servers:
            return PickServerServerSectionTableHeaderView.height
        default:
            return .leastNonzeroMagnitude
        }
    }
    
}

// MARK: - PickServerServerSectionTableHeaderViewDelegate
extension MastodonPickServerViewController: PickServerServerSectionTableHeaderViewDelegate {
    func pickServerServerSectionTableHeaderView(_ headerView: PickServerServerSectionTableHeaderView, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let diffableDataSource = headerView.diffableDataSource,
              let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .category(_):
            viewModel.selectCategoryItem.value = item
        case .language(_), .signupSpeed(_):
            break
            // gets handled by button
        }
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonPickServerViewController: OnboardingViewControllerAppearance { }

// MARK: - UISearchResultsUpdating

extension MastodonPickServerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.searchText.send(searchText)
    }
}
