//
//  SidebarViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import os.log
import UIKit
import Combine
import CoreDataStack

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectTab tab: MainTabBarController.Tab)
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectSearchHistory searchHistoryViewModel: SidebarViewModel.SearchHistoryViewModel)
}

final class SidebarViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SidebarViewModel!
    
    weak var delegate: SidebarViewControllerDelegate?
    
    let settingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.tintColor = Asset.Colors.brandBlue.color
        barButtonItem.image = UIImage(systemName: "gear")?.withRenderingMode(.alwaysTemplate)
        return barButtonItem
    }()

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            if sectionIndex == SidebarViewModel.Section.tab.rawValue {
                // with indentation
                configuration.headerMode = .none
            } else {
                // remove indentation
                configuration.headerMode = .firstItemInSection
            }
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
        return layout
    }
    
    let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: SidebarViewController.createLayout())
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
}

extension SidebarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.context.authenticationService.activeMastodonAuthenticationBox
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeMastodonAuthenticationBox in
                guard let self = self else { return }
                let domain = activeMastodonAuthenticationBox?.domain
                self.navigationItem.backBarButtonItem = {
                    let barButtonItem = UIBarButtonItem()
                    barButtonItem.image = UIImage(systemName: "sidebar.leading")
                    return barButtonItem
                }()
                self.navigationItem.title = domain
            }
            .store(in: &disposeBag)
        navigationItem.rightBarButtonItem = settingBarButtonItem
        settingBarButtonItem.target = self
        settingBarButtonItem.action = #selector(SidebarViewController.settingBarButtonItemPressed(_:))
        navigationController?.navigationBar.prefersLargeTitles = true

        setupBackground(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackground(theme: theme)
            }
            .store(in: &disposeBag)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(collectionView: collectionView)
    }
    
    private func setupBackground(theme: Theme) {
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithOpaqueBackground()
        barAppearance.backgroundColor = theme.sidebarBackgroundColor
        barAppearance.shadowColor = .clear
        barAppearance.shadowImage = UIImage()   // remove separator line
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        
        view.backgroundColor = theme.sidebarBackgroundColor
    }
    
}

extension SidebarViewController {
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let setting = context.settingService.currentSetting.value else { return }
        let settingsViewModel = SettingsViewModel(context: context, setting: setting)
        coordinator.present(scene: .settings(viewModel: settingsViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
}

// MARK: - UICollectionViewDelegate
extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .tab(let tab):
            delegate?.sidebarViewController(self, didSelectTab: tab)
        case .searchHistory(let viewModel):
            delegate?.sidebarViewController(self, didSelectSearchHistory: viewModel)
        case .header:
            break
        case .account(let viewModel):
            assert(Thread.isMainThread)
            let authentication = context.managedObjectContext.object(with: viewModel.authenticationObjectID) as! MastodonAuthentication
            context.authenticationService.activeMastodonUser(domain: authentication.domain, userID: authentication.userID)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    guard let self = self else { return }
                    self.coordinator.setup()
                }
                .store(in: &disposeBag)
        case .addAccount:
            coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
        }
    }
}
