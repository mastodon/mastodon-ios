//
//  ProfileAboutViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-22.
//

import os.log
import UIKit
import Combine
import MastodonSDK
import MastodonMeta
import Kanna

final class ProfileAboutViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    @Published var isEditing = false
    @Published var accountForEdit: Mastodon.Entity.Account?
    @Published var emojiMeta: MastodonContent.Emojis = [:]
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<ProfileFieldSection, ProfileFieldItem>?
    
    let displayProfileInfo = ProfileInfo()
    let editProfileInfo = ProfileInfo()
    let editProfileInfoDidInitialized = CurrentValueSubject<Void, Never>(Void()) // needs trigger initial event

    init(context: AppContext) {
        self.context = context
        // end init
        
        Publishers.CombineLatest(
            $isEditing.removeDuplicates(),   // only trigger when value toggle
            $accountForEdit
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, account in
            guard let self = self else { return }
            guard isEditing else { return }
            
            // setup editing value when toggle to editing
            self.editProfileInfo.fields = account?.source?.fields?.compactMap { field in
                ProfileFieldItem.FieldValue(
                    name: field.name,
                    value: field.value,
                    emojiMeta: [:]      // no use for editing
                )
            } ?? []
            self.editProfileInfoDidInitialized.send()
        }
        .store(in: &disposeBag)
    }
    
}

extension ProfileAboutViewModel {
    class ProfileInfo {
        @Published var fields: [ProfileFieldItem.FieldValue] = []
    }
}

extension ProfileAboutViewModel {
    func appendFieldItem() {
        var fields = editProfileInfo.fields
        guard fields.count < ProfileHeaderViewModel.maxProfileFieldCount else { return }
        fields.append(ProfileFieldItem.FieldValue(name: "", value: "", emojiMeta: [:]))
        editProfileInfo.fields = fields
    }
    
    func removeFieldItem(item: ProfileFieldItem) {
        var fields = editProfileInfo.fields
        guard case let .editField(field) = item else { return }
        guard let removeIndex = fields.firstIndex(of: field) else { return }
        fields.remove(at: removeIndex)
        editProfileInfo.fields = fields
    }
}

// MARK: - ProfileViewModelEditable
extension ProfileAboutViewModel: ProfileViewModelEditable {
    func isEdited() -> Bool {
        guard isEditing else { return false }
        
        let isFieldsEqual: Bool = {
            let originalFields = self.accountForEdit?.source?.fields?.compactMap { field in
                ProfileFieldItem.FieldValue(name: field.name, value: field.value, emojiMeta: [:])
            } ?? []
            let editFields = editProfileInfo.fields
            guard editFields.count == originalFields.count else { return false }
            for (editField, originalField) in zip(editFields, originalFields) {
                guard editField.name.value == originalField.name.value,
                      editField.value.value == originalField.value.value else {
                    return false
                }
            }
            return true
        }()
        guard isFieldsEqual else { return true }
        
        return false
    }
}
