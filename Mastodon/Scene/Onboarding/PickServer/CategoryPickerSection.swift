//
//  CategoryPickerSection.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import UIKit
import MastodonAsset
import MastodonLocalization
import MastodonCore

enum CategoryPickerSection: Equatable, Hashable {
    case main
}

extension CategoryPickerSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: UIViewController,
        viewModel: MastodonPickServerViewModel
    ) -> UICollectionViewDiffableDataSource<CategoryPickerSection, CategoryPickerItem> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak dependency] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let _ = dependency else { return nil }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PickServerCategoryCollectionViewCell.reuseIdentifier, for: indexPath) as? PickServerCategoryCollectionViewCell else {
                assertionFailure("unexpected cell dequeued")
                return nil
            }

            cell.titleLabel.text = item.title

            switch item {
            case .category(_):
                cell.chevron.isHidden = true
                cell.menuButton.isUserInteractionEnabled = false
                cell.menuButton.isHidden = true
                cell.menuButton.menu = nil
            case .language(_):
                guard viewModel.allLanguages.value.isNotEmpty else { break }

                let allLanguagesAction = UIAction(title: L10n.Scene.ServerPicker.Language.all) { _ in
                    viewModel.selectedLanguage.value = nil
                    FeedbackGenerator.shared.generate(.selectionChanged)
                    cell.titleLabel.text = L10n.Scene.ServerPicker.Button.language
                }

                let languageActions = viewModel.allLanguages.value.compactMap { language in
                    UIAction(title: language.language ?? language.locale) { action in
                        FeedbackGenerator.shared.generate(.selectionChanged)
                        viewModel.selectedLanguage.value = language.locale
                        cell.titleLabel.text = language.language
                    }
                }

                var allActions = [allLanguagesAction]
                allActions.append(contentsOf: languageActions)

                let languageMenu = UIMenu(title: L10n.Scene.ServerPicker.Button.language,
                                          children: allActions)

                cell.chevron.isHidden = false
                cell.menuButton.isUserInteractionEnabled = true
                cell.menuButton.isHidden = false
                cell.menuButton.menu = languageMenu
                cell.menuButton.showsMenuAsPrimaryAction = true

            case .signupSpeed(_):
                let doesntMatterAction = UIAction(title: L10n.Scene.ServerPicker.SignupSpeed.all) { _ in
                    viewModel.manualApprovalRequired.value = nil
                    cell.titleLabel.text = L10n.Scene.ServerPicker.Button.signupSpeed
                    FeedbackGenerator.shared.generate(.selectionChanged)
                }

                let manualApprovalAction = UIAction(title: L10n.Scene.ServerPicker.SignupSpeed.manuallyReviewed) { action in
                    viewModel.manualApprovalRequired.value = true
                    cell.titleLabel.text = action.title
                    FeedbackGenerator.shared.generate(.selectionChanged)
                }

                let instantSignupAction = UIAction(title: L10n.Scene.ServerPicker.SignupSpeed.instant) { action in
                    viewModel.manualApprovalRequired.value = false
                    cell.titleLabel.text = action.title
                    FeedbackGenerator.shared.generate(.selectionChanged)
                }

                let signupSpeedMenu = UIMenu(title: L10n.Scene.ServerPicker.Button.signupSpeed,
                                             children: [doesntMatterAction, manualApprovalAction, instantSignupAction])

                cell.chevron.isHidden = false
                cell.menuButton.isUserInteractionEnabled = true
                cell.menuButton.isHidden = false
                cell.menuButton.menu = signupSpeedMenu
                cell.menuButton.showsMenuAsPrimaryAction = true
            }

            cell.observe(\.isSelected, options: [.initial, .new]) { cell, _ in

                let textColor: UIColor
                let backgroundColor: UIColor
                let borderColor: UIColor

                if cell.isSelected {
                    textColor = .white
                    backgroundColor = Asset.Colors.Brand.blurple.color
                    borderColor = Asset.Colors.Brand.blurple.color
                } else {
                    textColor = .label
                    backgroundColor = .clear
                    borderColor = .separator
                }

                cell.backgroundColor = backgroundColor
                cell.titleLabel.textColor = textColor
                cell.layer.borderColor = borderColor.cgColor
                cell.chevron.tintColor = textColor
            }
            .store(in: &cell.observations)
            
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.accessibilityDescription
            cell.accessibilityTraits = .button

            return cell
        }
    }
}
