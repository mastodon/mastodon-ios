//
//  ProfileAboutViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-22.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import MastodonLocalization
import TabBarPager
import XLPagerTabStrip
import MastodonCore

protocol ProfileAboutViewControllerDelegate: AnyObject {
    func profileAboutViewController(_ viewController: ProfileAboutViewController, profileFieldCollectionViewCell: ProfileFieldCollectionViewCell, metaLabel: MetaLabel, didSelectMeta meta: Meta)
}

final class ProfileAboutViewController: UIViewController {
    
    let logger = Logger(subsystem: "ProfileAboutViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    weak var delegate: ProfileAboutViewControllerDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileAboutViewModel!
    
    let collectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
 
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfileAboutViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeService.shared.currentTheme.value.systemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.systemBackgroundColor
            }
            .store(in: &disposeBag)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.pinToParent()
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            profileFieldCollectionViewCellDelegate: self,
            profileFieldEditCollectionViewCellDelegate: self
        )
        
        let longPressReorderGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(ProfileAboutViewController.longPressReorderGestureHandler(_:))
        )
        collectionView.addGestureRecognizer(longPressReorderGesture)
    }
    
}

extension ProfileAboutViewController {
    // seealso: ProfileAboutViewModel.setupProfileDiffableDataSource(…)
    @objc private func longPressReorderGestureHandler(_ sender: UILongPressGestureRecognizer) {
        guard sender.view === collectionView else {
            assertionFailure()
            return
        }
        
        guard let diffableDataSource = self.viewModel.diffableDataSource else {
            collectionView.cancelInteractiveMovement()
            return
        }
        
        switch(sender.state) {
        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
                  let item = diffableDataSource.itemIdentifier(for: indexPath), case .editField = item,
                  let layoutAttribute = collectionView.layoutAttributesForItem(at: indexPath) else {
                break
            }
            
            let point = sender.location(in: collectionView)
            guard layoutAttribute.frame.contains(point) else {
                return
            }

            collectionView.beginInteractiveMovementForItem(at: indexPath)
        case .changed:
            guard let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) else {
                break
            }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath), case .editField = item else {
                collectionView.cancelInteractiveMovement()
                return
            }

            var position = sender.location(in: collectionView)
            position.x = collectionView.frame.width * 0.5
            collectionView.updateInteractiveMovementTargetPosition(position)
        case .ended:
            collectionView.endInteractiveMovement()
            collectionView.reloadData()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}
            
// MARK: - UICollectionViewDelegate
extension ProfileAboutViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select \(indexPath.debugDescription)")
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .addEntry:
            viewModel.appendFieldItem()
        default:
            break
        }
    }
}

// MARK: - ProfileFieldCollectionViewCellDelegate
extension ProfileAboutViewController: ProfileFieldCollectionViewCellDelegate {
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, metaLebel: MetaLabel, didSelectMeta meta: Meta) {
        delegate?.profileAboutViewController(self, profileFieldCollectionViewCell: cell, metaLabel: metaLebel, didSelectMeta: meta)
    }
}

// MARK: - ProfileFieldEditCollectionViewCellDelegate
extension ProfileAboutViewController: ProfileFieldEditCollectionViewCellDelegate {
    func profileFieldEditCollectionViewCell(_ cell: ProfileFieldEditCollectionViewCell, editButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.removeFieldItem(item: item)
    }
}

// MARK: - ScrollViewContainer
extension ProfileAboutViewController: ScrollViewContainer {
    var scrollView: UIScrollView { collectionView }
}

// MARK: - TabBarPage
extension ProfileAboutViewController: TabBarPage {
    var pageScrollView: UIScrollView { scrollView }
}

// MARK: - IndicatorInfoProvider
extension ProfileAboutViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: L10n.Scene.Profile.SegmentedControl.about)
    }
}
