//
//  ProfileHeaderViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-9.
//

import UIKit
import Combine
import Kanna
import MastodonSDK

final class ProfileHeaderViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let isEditing = CurrentValueSubject<Bool, Never>(false)
    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    let needsSetupBottomShadow = CurrentValueSubject<Bool, Never>(true)
    let isTitleViewContentOffsetSet = CurrentValueSubject<Bool, Never>(false)
    
    // output
    let displayProfileInfo = ProfileInfo()
    let editProfileInfo = ProfileInfo()
    let isTitleViewDisplaying = CurrentValueSubject<Bool, Never>(false)
    
    init(context: AppContext) {
        self.context = context
        
        isEditing
            .removeDuplicates()     // only triiger when value toggle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing in
                guard let self = self else { return }
                // setup editing value when toggle to editing
                self.editProfileInfo.name.value = self.displayProfileInfo.name.value    // set to name
                self.editProfileInfo.avatarImageResource.value = .image(nil)            // set to empty
                self.editProfileInfo.note.value = ProfileHeaderViewModel.normalize(note: self.displayProfileInfo.note.value)
            }
            .store(in: &disposeBag)
    }
    
}

extension ProfileHeaderViewModel {
    struct ProfileInfo {
        let name = CurrentValueSubject<String?, Never>(nil)
        let avatarImageResource = CurrentValueSubject<ImageResource?, Never>(nil)
        let note = CurrentValueSubject<String?, Never>(nil)
        
        enum ImageResource {
            case url(URL?)
            case image(UIImage?)
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
    
    // check if profile chagned or not
    func isProfileInfoEdited() -> Bool {
        guard isEditing.value else { return false }
        
        guard editProfileInfo.name.value == displayProfileInfo.name.value else { return true }
        guard case let .image(image) =  editProfileInfo.avatarImageResource.value, image == nil else { return true }
        guard editProfileInfo.note.value == ProfileHeaderViewModel.normalize(note: displayProfileInfo.note.value) else { return true }
        
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
        
        let query = Mastodon.API.Account.UpdateCredentialQuery(
            discoverable: nil,
            bot: nil,
            displayName: editProfileInfo.name.value,
            note: editProfileInfo.note.value,
            avatar: image.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: nil,
            locked: nil,
            source: nil,
            fieldsAttributes: nil       // TODO:
        )
        return context.apiService.accountUpdateCredentials(
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
    
}
