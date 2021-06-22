//
//  ProfileHeaderViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-9.
//

import os.log
import UIKit
import Combine
import Kanna
import MastodonSDK

final class ProfileHeaderViewModel {
    
    static let maxProfileFieldCount = 4
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let isEditing = CurrentValueSubject<Bool, Never>(false)
    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    let needsSetupBottomShadow = CurrentValueSubject<Bool, Never>(true)
    let isTitleViewContentOffsetSet = CurrentValueSubject<Bool, Never>(false)
    let emojiDict = CurrentValueSubject<MastodonStatusContent.EmojiDict, Never>([:])
    
    // output
    let displayProfileInfo = ProfileInfo()
    let editProfileInfo = ProfileInfo()
    let isTitleViewDisplaying = CurrentValueSubject<Bool, Never>(false)
    var fieldDiffableDataSource: UICollectionViewDiffableDataSource<ProfileFieldSection, ProfileFieldItem>!
    
    init(context: AppContext) {
        self.context = context
        
        isEditing
            .removeDuplicates()     // only triiger when value toggle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing in
                guard let self = self else { return }
                // setup editing value when toggle to editing
                self.editProfileInfo.name.value = self.displayProfileInfo.name.value        // set to name
                self.editProfileInfo.avatarImageResource.value = .image(nil)                // set to empty
                self.editProfileInfo.note.value = ProfileHeaderViewModel.normalize(note: self.displayProfileInfo.note.value)
                self.editProfileInfo.fields.value = self.displayProfileInfo.fields.value.map { $0.duplicate() }    // set to fields
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest4(
            isEditing.removeDuplicates(),
            displayProfileInfo.fields.removeDuplicates(),
            editProfileInfo.fields.removeDuplicates(),
            emojiDict.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isEditing, displayFields, editingFields, emojiDict in
            guard let self = self else { return }
            guard let diffableDataSource = self.fieldDiffableDataSource else { return }
            
            var snapshot = NSDiffableDataSourceSnapshot<ProfileFieldSection, ProfileFieldItem>()
            snapshot.appendSections([.main])

            let oldSnapshot = diffableDataSource.snapshot()
            let oldFieldAttributeDict: [UUID: ProfileFieldItem.FieldItemAttribute] = {
                var dict: [UUID: ProfileFieldItem.FieldItemAttribute] = [:]
                for item in oldSnapshot.itemIdentifiers {
                    switch item {
                    case .field(let field, let attribute):
                        dict[field.id] = attribute
                    default:
                        continue
                    }
                }
                return dict
            }()
            let fields: [ProfileFieldItem.FieldValue] = isEditing ? editingFields : displayFields
            var items = fields.map { field -> ProfileFieldItem in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: process field item ID: %s", ((#file as NSString).lastPathComponent), #line, #function, field.id.uuidString)

                let attribute = oldFieldAttributeDict[field.id] ?? ProfileFieldItem.FieldItemAttribute()
                attribute.isEditing = isEditing
                attribute.emojiDict.value = emojiDict
                attribute.isLast = false
                return ProfileFieldItem.field(field: field, attribute: attribute)
            }
            
            if isEditing, fields.count < ProfileHeaderViewModel.maxProfileFieldCount {
                items.append(.addEntry(attribute: ProfileFieldItem.AddEntryItemAttribute()))
            }
            
            if let last = items.last?.listSeparatorLineConfigurable {
                last.isLast = true
            }

            snapshot.appendItems(items, toSection: .main)
            
            diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
        .store(in: &disposeBag)
    }
    
}

extension ProfileHeaderViewModel {
    struct ProfileInfo {
        let name = CurrentValueSubject<String?, Never>(nil)
        let avatarImageResource = CurrentValueSubject<ImageResource?, Never>(nil)
        let note = CurrentValueSubject<String?, Never>(nil)
        let fields = CurrentValueSubject<[ProfileFieldItem.FieldValue], Never>([])
        
        enum ImageResource {
            case url(URL?)
            case image(UIImage?)
        }
    }
}

extension ProfileHeaderViewModel {
    func appendFieldItem() {
        var fields = editProfileInfo.fields.value
        guard fields.count < ProfileHeaderViewModel.maxProfileFieldCount else { return }
        fields.append(ProfileFieldItem.FieldValue(name: "", value: ""))
        editProfileInfo.fields.value = fields
    }
    
    func removeFieldItem(item: ProfileFieldItem) {
        var fields = editProfileInfo.fields.value
        guard case let .field(field, _) = item else { return }
        guard let removeIndex = fields.firstIndex(of: field) else { return }
        fields.remove(at: removeIndex)
        editProfileInfo.fields.value = fields
    }
}

extension ProfileHeaderViewModel {
    
    static func normalize(note: String?) -> String? {
        guard let note = note?.trimmingCharacters(in: .whitespacesAndNewlines),!note.isEmpty else {
            return nil
        }
        
        let html = try? HTML(html: note, encoding: .utf8)
        return html?.text
    }
    
    // check if profile change or not
    func isProfileInfoEdited() -> Bool {
        guard isEditing.value else { return false }
        
        guard editProfileInfo.name.value == displayProfileInfo.name.value else { return true }
        guard case let .image(image) =  editProfileInfo.avatarImageResource.value, image == nil else { return true }
        guard editProfileInfo.note.value == ProfileHeaderViewModel.normalize(note: displayProfileInfo.note.value) else { return true }
        let isFieldsEqual: Bool = {
            let editFields = editProfileInfo.fields.value
            let displayFields = displayProfileInfo.fields.value
            guard editFields.count == displayFields.count else { return false }
            for (editField, displayField) in zip(editFields, displayFields) {
                guard editField.name.value == displayField.name.value,
                      editField.value.value == displayField.value.value else {
                    return false
                }
            }
            return true
        }()
        guard isFieldsEqual else { return true }
        
        return false
    }
    
    func updateProfileInfo() -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return Fail(error: APIService.APIError.implicit(.badRequest)).eraseToAnyPublisher()
        }
        let domain = activeMastodonAuthenticationBox.domain
        let authorization = activeMastodonAuthenticationBox.userAuthorization
        
        let image: UIImage? = {
            guard case let .image(_image) = editProfileInfo.avatarImageResource.value else { return nil }
            guard let image = _image else { return nil }
            guard image.size.width <= MastodonRegisterViewController.avatarImageMaxSizeInPixel.width else {
                return image.af.imageScaled(to: MastodonRegisterViewController.avatarImageMaxSizeInPixel)
            }
            return image
        }()
        
        let fieldsAttributes = editProfileInfo.fields.value.map { fieldValue in
            Mastodon.Entity.Field(name: fieldValue.name.value, value: fieldValue.value.value)
        }
        
        let query = Mastodon.API.Account.UpdateCredentialQuery(
            discoverable: nil,
            bot: nil,
            displayName: editProfileInfo.name.value,
            note: editProfileInfo.note.value,
            avatar: image.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: nil,
            locked: nil,
            source: nil,
            fieldsAttributes: fieldsAttributes
        )
        return context.apiService.accountUpdateCredentials(
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
    
}
