//
//  SidebarViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import UIKit
import Combine
import CoreDataStack

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectTab tab: MainTabBarController.Tab)
}

final class SidebarViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SidebarViewModel!
    
    weak var delegate: SidebarViewControllerDelegate?

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
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
        
        navigationItem.title = "Title"
        navigationController?.navigationBar.prefersLargeTitles = true

        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        
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
    
}

// MARK: - UICollectionViewDelegate
extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .tab(let tab):
            delegate?.sidebarViewController(self, didSelectTab: tab)
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
        default:
            // TODO:
            break
        }
    }
}
