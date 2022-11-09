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
