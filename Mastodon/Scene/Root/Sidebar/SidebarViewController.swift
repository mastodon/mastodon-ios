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
import MastodonCore
import MastodonUI

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectTab tab: MainTabBarController.Tab)
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didLongPressItem item: SidebarViewModel.Item, sourceView: UIView)
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didDoubleTapItem item: SidebarViewModel.Item, sourceView: UIView)
}

final class SidebarViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "SidebarViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    var viewModel: SidebarViewModel!
    
    weak var delegate: SidebarViewControllerDelegate?

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            switch sectionIndex {
            case 0:
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(100)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
            default:
                break
            }
            return section
        }
        return layout
    }
    
    let collectionView: UICollectionView = {
        let layout = SidebarViewController.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceVertical = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    static func createSecondaryLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
        return layout
    }
    
    let secondaryCollectionView: UICollectionView = {
        let layout = SidebarViewController.createSecondaryLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = false
        collectionView.alwaysBounceVertical = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    var secondaryCollectionViewHeightLayoutConstraint: NSLayoutConstraint!
}

extension SidebarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)

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
        collectionView.pinToParent()
        
        secondaryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(secondaryCollectionView)
        secondaryCollectionViewHeightLayoutConstraint = secondaryCollectionView.heightAnchor.constraint(equalToConstant: 44).priority(.required - 1)
        NSLayoutConstraint.activate([
            secondaryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            secondaryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: secondaryCollectionView.bottomAnchor),
            secondaryCollectionViewHeightLayoutConstraint,
        ])
        
        collectionView.delegate = self
        secondaryCollectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            secondaryCollectionView: secondaryCollectionView
        )
        
        secondaryCollectionView.observe(\.contentSize, options: [.initial, .new]) { [weak self] secondaryCollectionView, _ in
            guard let self = self else { return }
            
            let contentHeight = secondaryCollectionView.contentSize.height
            guard contentHeight > 0 else { return }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): secondaryCollectionView contentSize: \(secondaryCollectionView.contentSize.debugDescription)")
            
            let currentFrameHeight = secondaryCollectionView.frame.height
            guard currentFrameHeight < contentHeight else { return }
            
            self.secondaryCollectionViewHeightLayoutConstraint.constant = contentHeight
            self.collectionView.contentInset.bottom = contentHeight
        }
        .store(in: &observations)
        
        let sidebarLongPressGestureRecognizer = UILongPressGestureRecognizer()
        sidebarLongPressGestureRecognizer.addTarget(self, action: #selector(SidebarViewController.sidebarLongPressGestureRecognizerHandler(_:)))
        collectionView.addGestureRecognizer(sidebarLongPressGestureRecognizer)
        
        // todo: reconsider the "double tap to change account" feature -> https://github.com/mastodon/mastodon-ios/issues/628
//        let sidebarDoubleTapGestureRecognizer = UITapGestureRecognizer()
//        sidebarDoubleTapGestureRecognizer.numberOfTapsRequired = 2
//        sidebarDoubleTapGestureRecognizer.addTarget(self, action: #selector(SidebarViewController.sidebarDoubleTapGestureRecognizerHandler(_:)))
//        sidebarDoubleTapGestureRecognizer.delaysTouchesEnded = false
//        sidebarDoubleTapGestureRecognizer.cancelsTouchesInView = true
//        collectionView.addGestureRecognizer(sidebarDoubleTapGestureRecognizer)

    }
    
    private func setupBackground(theme: Theme) {
        let color: UIColor = theme.sidebarBackgroundColor
        view.backgroundColor = color
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { context in
            self.collectionView.collectionViewLayout.invalidateLayout()
        } completion: { context in
            // do nothing
        }
    }
    
}

extension SidebarViewController {
    @objc private func sidebarLongPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        assert(sender.view === collectionView)
        
        let position = sender.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: position) else { return }
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        delegate?.sidebarViewController(self, didLongPressItem: item, sourceView: cell)
    }
    
    @objc private func sidebarDoubleTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        assert(sender.view === collectionView)
        
        let position = sender.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: position) else { return }
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        delegate?.sidebarViewController(self, didDoubleTapItem: item, sourceView: cell)
    }

}

// MARK: - UICollectionViewDelegate
extension SidebarViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case self.collectionView:
            guard let diffableDataSource = viewModel.diffableDataSource else { return }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            switch item {
            case .tab(let tab):
                delegate?.sidebarViewController(self, didSelectTab: tab)
            case .setting:
                guard let authContext = viewModel.authContext else { return }
                guard let setting = context.settingService.currentSetting.value else { return }
                let settingsViewModel = SettingsViewModel(context: context, authContext: authContext, setting: setting)
                _ = coordinator.present(scene: .settings(viewModel: settingsViewModel), from: self, transition: .modal(animated: true, completion: nil))
            case .compose:
                assertionFailure()
            }
        case secondaryCollectionView:
            guard let diffableDataSource = viewModel.secondaryDiffableDataSource else { return }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            
            guard let authContext = viewModel.authContext else { return }
            switch item {
            case .compose:
                let composeViewModel = ComposeViewModel(
                    context: context,
                    authContext: authContext,
                    destination: .topLevel
                )
                _ = coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
            default:
                assertionFailure()
            }
        default:
            assertionFailure()
        }
    }
}
