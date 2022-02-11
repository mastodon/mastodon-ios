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
import MastodonMeta

final class ProfileHeaderViewModel {
    
    static let avatarImageMaxSizeInPixel = CGSize(width: 400, height: 400)
    static let maxProfileFieldCount = 4
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    @Published var isEditing = false
    @Published var accountForEdit: Mastodon.Entity.Account?
    @Published var emojiMeta: MastodonContent.Emojis = [:]
    
    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    let needsSetupBottomShadow = CurrentValueSubject<Bool, Never>(true)
    let needsFiledCollectionViewHidden = CurrentValueSubject<Bool, Never>(false)
    let isTitleViewContentOffsetSet = CurrentValueSubject<Bool, Never>(false)
    
    // output
    let isTitleViewDisplaying = CurrentValueSubject<Bool, Never>(false)
    let displayProfileInfo = ProfileInfo()
    let editProfileInfo = ProfileInfo()
    let editProfileInfoDidInitialized = CurrentValueSubject<Void, Never>(Void()) // needs trigger initial event

    init(context: AppContext) {
        self.context = context
    
        Publishers.CombineLatest(
            $isEditing.removeDuplicates(),   // only trigger when value toggle
            $accountForEdit
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, account in
            guard let self = self else { return }
            guard isEditing else { return }
            // setup editing value when toggle to editing
            self.editProfileInfo.name = self.displayProfileInfo.name        // set to name
            self.editProfileInfo.avatarImage = nil                          // set to empty
            self.editProfileInfo.note = ProfileHeaderViewModel.normalize(note: self.displayProfileInfo.note)
            self.editProfileInfoDidInitialized.send()
        }
        .store(in: &disposeBag)
    }
    
}

extension ProfileHeaderViewModel {
    class ProfileInfo {
        // input
        @Published var name: String?
        @Published var avatarImageURL: URL?
        @Published var avatarImage: UIImage?
        @Published var note: String?
        
        // output
        @Published var avatarImageResource = ImageResource(url: nil, image: nil)
        
        struct ImageResource {
            let url: URL?
            let image: UIImage?
        }
        
        init() {
            Publishers.CombineLatest(
                $avatarImageURL,
                $avatarImage
            )
            .map { url, image in
                ImageResource(url: url, image: image)
            }
            .assign(to: &$avatarImageResource)
        }
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

}


// MARK: - ProfileViewModelEditable
extension ProfileHeaderViewModel: ProfileViewModelEditable {
    func isEdited() -> Bool {
        guard isEditing else { return false }
        
        guard editProfileInfo.name == displayProfileInfo.name else { return true }
        guard editProfileInfo.avatarImage == nil else { return true }
        guard editProfileInfo.note == ProfileHeaderViewModel.normalize(note: displayProfileInfo.note) else { return true }

        return false
    }
}
