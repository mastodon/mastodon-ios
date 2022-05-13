//
//  MastodonRegisterViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import UIKit
import Combine
import MastodonAsset
import MastodonLocalization

extension MastodonRegisterViewModel {
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        tableView.register(OnboardingHeadlineTableViewCell.self, forCellReuseIdentifier: String(describing: OnboardingHeadlineTableViewCell.self))
        tableView.register(MastodonRegisterAvatarTableViewCell.self, forCellReuseIdentifier: String(describing: MastodonRegisterAvatarTableViewCell.self))
        tableView.register(MastodonRegisterTextFieldTableViewCell.self, forCellReuseIdentifier: String(describing: MastodonRegisterTextFieldTableViewCell.self))
        tableView.register(MastodonRegisterPasswordHintTableViewCell.self, forCellReuseIdentifier: String(describing: MastodonRegisterPasswordHintTableViewCell.self))
        
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .header(let domain):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: OnboardingHeadlineTableViewCell.self), for: indexPath) as! OnboardingHeadlineTableViewCell
                cell.titleLabel.text = L10n.Scene.Register.letsGetYouSetUpOnDomain(domain)
                cell.subTitleLabel.isHidden = true
                return cell
            case .avatar:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MastodonRegisterAvatarTableViewCell.self), for: indexPath) as! MastodonRegisterAvatarTableViewCell
                self.configureAvatar(cell: cell)
                return cell
            case .name:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MastodonRegisterTextFieldTableViewCell.self), for: indexPath) as! MastodonRegisterTextFieldTableViewCell
                cell.setupTextViewPlaceholder(text: L10n.Scene.Register.Input.DisplayName.placeholder)
                cell.textField.keyboardType = .default
                cell.textField.autocapitalizationType = .words
                cell.textField.text = self.name
                NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: cell.textField)
                    .receive(on: DispatchQueue.main)
                    .compactMap { notification in
                        guard let textField = notification.object as? UITextField else {
                            assertionFailure()
                            return nil
                        }
                        return textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    }
                    .assign(to: \.name, on: self)
                    .store(in: &cell.disposeBag)
                return cell
            case .username:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MastodonRegisterTextFieldTableViewCell.self), for: indexPath) as! MastodonRegisterTextFieldTableViewCell
                cell.setupTextViewRightView(text: "@" + self.domain)
                cell.setupTextViewPlaceholder(text: L10n.Scene.Register.Input.Username.placeholder)
                cell.textField.keyboardType = .alphabet
                cell.textField.autocorrectionType = .no
                cell.textField.text = self.username
                cell.textField.textAlignment = .left
                cell.textField.semanticContentAttribute = .forceLeftToRight
                NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: cell.textField)
                    .receive(on: DispatchQueue.main)
                    .compactMap { notification in
                        guard let textField = notification.object as? UITextField else {
                            assertionFailure()
                            return nil
                        }
                        return textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    }
                    .assign(to: \.username, on: self)
                    .store(in: &cell.disposeBag)
                self.configureTextFieldCell(cell: cell, validateState: self.$usernameValidateState)
                return cell
            case .email:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MastodonRegisterTextFieldTableViewCell.self), for: indexPath) as! MastodonRegisterTextFieldTableViewCell
                cell.setupTextViewPlaceholder(text: L10n.Scene.Register.Input.Email.placeholder)
                cell.textField.keyboardType = .emailAddress
                cell.textField.autocorrectionType = .no
                cell.textField.text = self.email
                NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: cell.textField)
                    .receive(on: DispatchQueue.main)
                    .compactMap { notification in
                        guard let textField = notification.object as? UITextField else {
                            assertionFailure()
                            return nil
                        }
                        return textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    }
                    .assign(to: \.email, on: self)
                    .store(in: &cell.disposeBag)
                self.configureTextFieldCell(cell: cell, validateState: self.$emailValidateState)
                return cell
            case .password:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MastodonRegisterTextFieldTableViewCell.self), for: indexPath) as! MastodonRegisterTextFieldTableViewCell
                cell.setupTextViewPlaceholder(text: L10n.Scene.Register.Input.Password.placeholder)
                cell.textField.keyboardType = .alphabet
                cell.textField.autocorrectionType = .no
                cell.textField.isSecureTextEntry = true
                cell.textField.text = self.password
                cell.textField.textAlignment = .left
                cell.textField.semanticContentAttribute = .forceLeftToRight
                NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: cell.textField)
                    .receive(on: DispatchQueue.main)
                    .compactMap { notification in
                        guard let textField = notification.object as? UITextField else {
                            assertionFailure()
                            return nil
                        }
                        return textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    }
                    .assign(to: \.password, on: self)
                    .store(in: &cell.disposeBag)
                self.configureTextFieldCell(cell: cell, validateState: self.$passwordValidateState)
                return cell
            case .hint:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MastodonRegisterPasswordHintTableViewCell.self), for: indexPath) as! MastodonRegisterPasswordHintTableViewCell
                return cell
            case .reason:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MastodonRegisterTextFieldTableViewCell.self), for: indexPath) as! MastodonRegisterTextFieldTableViewCell
                cell.setupTextViewPlaceholder(text: L10n.Scene.Register.Input.Invite.registrationUserInviteRequest)
                cell.textField.keyboardType = .default
                cell.textField.text = self.reason
                NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: cell.textField)
                    .receive(on: DispatchQueue.main)
                    .compactMap { notification in
                        guard let textField = notification.object as? UITextField else {
                            assertionFailure()
                            return nil
                        }
                        return textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    }
                    .assign(to: \.reason, on: self)
                    .store(in: &cell.disposeBag)
                self.configureTextFieldCell(cell: cell, validateState: self.$reasonValidateState)
                return cell
            default:
                assertionFailure()
                return UITableViewCell()
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<RegisterSection, RegisterItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.header(domain: domain)], toSection: .main)
        snapshot.appendItems([.avatar, .name, .username, .email, .password, .hint], toSection: .main)
        if approvalRequired {
            snapshot.appendItems([.reason], toSection: .main)
        }
        diffableDataSource?.applySnapshot(snapshot, animated: false, completion: nil)
    }
}

extension MastodonRegisterViewModel {
    private func configureAvatar(cell: MastodonRegisterAvatarTableViewCell) {
        self.$avatarImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak cell] image in
                guard let self = self else { return }
                guard let cell = cell else { return }
                let image = image ?? Asset.Scene.Onboarding.avatarPlaceholder.image
                cell.avatarButton.setImage(image, for: .normal)
                cell.avatarButton.menu = self.createAvatarMediaContextMenu()
                cell.avatarButton.showsMenuAsPrimaryAction = true
            }
            .store(in: &cell.disposeBag)
    }
    
    private func configureTextFieldCell(
        cell: MastodonRegisterTextFieldTableViewCell,
        validateState: Published<ValidateState>.Publisher
    ) {
        Publishers.CombineLatest(
            validateState,
            cell.textField.publisher(for: \.isFirstResponder)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak cell] validateState, isFirstResponder in
            guard let cell = cell else { return }
            switch validateState {
            case .empty:
                cell.textFieldShadowContainer.shadowColor = isFirstResponder ? Asset.Colors.brandBlue.color : .black
                cell.textFieldShadowContainer.shadowAlpha = isFirstResponder ? 1 : 0.25
            case .valid:
                cell.textFieldShadowContainer.shadowColor = Asset.Colors.TextField.valid.color
                cell.textFieldShadowContainer.shadowAlpha = 1
            case .invalid:
                cell.textFieldShadowContainer.shadowColor = Asset.Colors.TextField.invalid.color
                cell.textFieldShadowContainer.shadowAlpha = 1
            }
        }
        .store(in: &cell.disposeBag)
    }
}
