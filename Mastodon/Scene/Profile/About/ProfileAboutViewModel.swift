//
//  ProfileAboutViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-22.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonSDK
import MastodonMeta
import MastodonCore
import Kanna

final class ProfileAboutViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    @Published var user: MastodonUser?
    @Published var isEditing = false
    @Published var accountForEdit: Mastodon.Entity.Account?
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<ProfileFieldSection, ProfileFieldItem>?
    let profileInfo = ProfileInfo()
    let profileInfoEditing = ProfileInfo()
    
    @Published var fields: [MastodonField] = []
    @Published var emojiMeta: MastodonContent.Emojis = [:]
    @Published var createdAt: Date = Date()

    init(context: AppContext) {
        self.context = context
        // end init
        
        $user
            .compactMap { $0 }
            .flatMap { $0.publisher(for: \.emojis) }
            .map { $0.asDictionary }
            .assign(to: &$emojiMeta)
        
        $user
            .compactMap { $0 }
            .flatMap { $0.publisher(for: \.fields) }
            .assign(to: &$fields)

        $user
            .compactMap { $0 }
            .flatMap { $0.publisher(for: \.createdAt) }
            .assign(to: &$createdAt)
        
        Publishers.CombineLatest(
            $fields,
            $emojiMeta
        )
        .map { fields, emojiMeta in
            fields.map { ProfileFieldItem.FieldValue(name: $0.name, value: $0.value, verifiedAt: $0.verifiedAt, emojiMeta: emojiMeta) }
        }
        .assign(to: &profileInfo.$fields)
        
        Publishers.CombineLatest(
            $accountForEdit,
            $emojiMeta
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] account, emojiMeta in
            guard let self = self else { return }
            guard let account = account else { return }
                
            // update profileInfo will occurs race condition issue
            // bind user.fields to profileInfo to avoid it
            
            self.profileInfoEditing.fields = account.source?.fields?.compactMap { field in
                ProfileFieldItem.FieldValue(
                    name: field.name,
                    value: field.value,
                    verifiedAt: field.verifiedAt,
                    emojiMeta: [:]      // no use for editing
                )
            } ?? []
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
        var fields = profileInfoEditing.fields
        guard fields.count < ProfileHeaderViewModel.maxProfileFieldCount else { return }
        fields.append(ProfileFieldItem.FieldValue(name: "", value: "", verifiedAt: nil, emojiMeta: [:]))
        profileInfoEditing.fields = fields
    }
    
    func removeFieldItem(item: ProfileFieldItem) {
        var fields = profileInfoEditing.fields
        guard case let .editField(field) = item else { return }
        guard let removeIndex = fields.firstIndex(of: field) else { return }
        fields.remove(at: removeIndex)
        profileInfoEditing.fields = fields
    }
}

// MARK: - ProfileViewModelEditable
extension ProfileAboutViewModel: ProfileViewModelEditable {
    var isEdited: Bool {
        guard isEditing else { return false }
        
        let isFieldsEqual: Bool = {
            let originalFields = self.accountForEdit?.source?.fields?.compactMap { field in
                ProfileFieldItem.FieldValue(name: field.name, value: field.value, verifiedAt: nil, emojiMeta: [:])
            } ?? []
            let editFields = profileInfoEditing.fields
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
