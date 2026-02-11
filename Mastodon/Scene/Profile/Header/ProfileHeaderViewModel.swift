//
//  ProfileHeaderViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-9.
//

import UIKit
import CoreDataStack
import Kanna
import MastodonSDK
import MastodonMeta
import MastodonCore
import MastodonUI

final class ProfileHeaderViewModel {
    
    static let avatarImageMaxSizeInPixel = CGSize(width: 400, height: 400)
    static let bannerImageMaxSizeInPixel = CGSize(width: 1500, height: 500)
    static let maxProfileFieldCount = 4
    
    // input
    let authenticationBox: MastodonAuthenticationBox
    
    @Published var me: Mastodon.Entity.Account
    @Published var account: Mastodon.Entity.Account
    @Published var relationship: Mastodon.Entity.Relationship?

    @Published var isMyself = false
    @Published var isEditing = false
    @Published var isUpdating = false
    
    @Published var accountForEdit: Mastodon.Entity.Account?

    // output
    let profileInfo        = ProfileInfo()
    let profileInfoEditing = ProfileInfo()

    @Published var isTitleViewDisplaying = false
    @Published var isTitleViewContentOffsetSet = false    

    init(authenticationBox: MastodonAuthenticationBox, account: Mastodon.Entity.Account, me: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?) {
        self.authenticationBox = authenticationBox
        self.account = account
        self.me = me
        self.relationship = relationship
    }
    
    public func setProfileInfo(accountForEdit: Mastodon.Entity.Account) {
        // banner
        profileInfo.header = nil
        profileInfoEditing.header = nil
        // avatar
        profileInfo.avatar = nil
        profileInfoEditing.avatar = nil

        let name = account.displayNameWithFallback
        profileInfo.name = name
        profileInfoEditing.name = name
        // bio
        let note = ProfileHeaderViewModel.normalize(note: account.note)
        profileInfo.note = note
        profileInfoEditing.note = note
    }
}

extension ProfileHeaderViewModel {
    class ProfileInfo {
        // input
        @Published var header: UIImage?
        @Published var avatar: UIImage?
        @Published var name: String?
        @Published var note: String?
    }
    
    var editedDetails: ProfileHeaderDetails {
        return ProfileHeaderDetails(bannerImage: profileInfoEditing.header, avatarImage: profileInfoEditing.avatar, displayName: profileInfoEditing.name, bioText: profileInfoEditing.note)
    }
}

extension ProfileHeaderViewModel {
    
    static func normalize(note: String?) -> String? {
        let _note = note?.replacingOccurrences(of: "<br>|<br />", with: "\u{2028}", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "</p>", with: "</p>\u{2029}", range: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let note = _note, !note.isEmpty else {
            return nil
        }
        
        let html = try? HTML(html: note, encoding: .utf8)
        return html?.text
    }

}

// MARK: - ProfileViewModelEditable
extension ProfileHeaderViewModel {
    var isEdited: Bool {
        guard isEditing else { return false }
        
        guard profileInfoEditing.header == nil else { return true }
        guard profileInfoEditing.avatar == nil else { return true }
        guard profileInfo.name == profileInfoEditing.name else { return true }
        guard profileInfo.note == profileInfoEditing.note else { return true }

        return false
    }
}
