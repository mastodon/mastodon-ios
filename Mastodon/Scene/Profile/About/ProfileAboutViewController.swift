//
//  ProfileAboutViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-22.
//

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
 
    public var currentEditableFields: [ (String, String) ] {
        return viewModel.profileInfoEditing.editedFields
    }
}

extension ProfileAboutViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.pinToParent()

        let longPressReorderGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(ProfileAboutViewController.longPressReorderGestureHandler(_:))
        )
        collectionView.addGestureRecognizer(longPressReorderGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            profileFieldCollectionViewCellDelegate: self,
            profileFieldEditCollectionViewCellDelegate: self
        )

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
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        delegate?.profileAboutViewController(self, profileFieldCollectionViewCell: cell, metaLabel: metaLabel, didSelectMeta: meta)
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
