//
//  ProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonSDK
import MastodonMeta
import MastodonAsset
import MastodonLocalization
import MastodonUI

// please override this base class
class ProfileViewModel: NSObject {
        
    let logger = Logger(subsystem: "ProfileViewModel", category: "ViewModel")
    
    typealias UserID = String
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private var mastodonUserObserver: AnyCancellable?
    private var currentMastodonUserObserver: AnyCancellable?
    
    let postsUserTimelineViewModel: UserTimelineViewModel
    let repliesUserTimelineViewModel: UserTimelineViewModel
    let mediaUserTimelineViewModel: UserTimelineViewModel
    let profileAboutViewModel: ProfileAboutViewModel
    
    // input
    let context: AppContext
    @Published var me: MastodonUser?
    @Published var user: MastodonUser?
    
    let viewDidAppear = PassthroughSubject<Void, Never>()
    
    @Published var isEditing = false
    @Published var isUpdating = false
        
    // output
    @Published var userIdentifier: UserIdentifier? = nil

//    let domain: CurrentValueSubject<String?, Never>
//    let userID: CurrentValueSubject<UserID?, Never>
//    let bannerImageURL: CurrentValueSubject<URL?, Never>
//    let avatarImageURL: CurrentValueSubject<URL?, Never>
//    let name: CurrentValueSubject<String?, Never>
//    let username: CurrentValueSubject<String?, Never>
//    let bioDescription: CurrentValueSubject<String?, Never>
//    let url: CurrentValueSubject<String?, Never>
//    let statusesCount: CurrentValueSubject<Int?, Never>
//    let followingCount: CurrentValueSubject<Int?, Never>
//    let followersCount: CurrentValueSubject<Int?, Never>
//    let fields: CurrentValueSubject<[MastodonField], Never>
//    let emojiMeta: CurrentValueSubject<MastodonContent.Emojis, Never>

    // fulfill this before editing
    let accountForEdit = CurrentValueSubject<Mastodon.Entity.Account?, Never>(nil)

//    let protected: CurrentValueSubject<Bool?, Never>
//    let suspended: CurrentValueSubject<Bool, Never>

//
//    let relationshipActionOptionSet = CurrentValueSubject<RelationshipActionOptionSet, Never>(.none)
//    let isFollowedBy = CurrentValueSubject<Bool, Never>(false)
//    let isMuting = CurrentValueSubject<Bool, Never>(false)
//    let isBlocking = CurrentValueSubject<Bool, Never>(false)
//    let isBlockedBy = CurrentValueSubject<Bool, Never>(false)
//
//    let isRelationshipActionButtonHidden = CurrentValueSubject<Bool, Never>(true)
//    let isReplyBarButtonItemHidden = CurrentValueSubject<Bool, Never>(true)
//    let isMoreMenuBarButtonItemHidden = CurrentValueSubject<Bool, Never>(true)
//    let isMeBarButtonItemsHidden = CurrentValueSubject<Bool, Never>(true)
//
//    let needsPagePinToTop = CurrentValueSubject<Bool, Never>(false)
//    let needsPagingEnabled = CurrentValueSubject<Bool, Never>(true)
//    let needsImageOverlayBlurred = CurrentValueSubject<Bool, Never>(false)
    
    init(context: AppContext, optionalMastodonUser mastodonUser: MastodonUser?) {
        self.context = context
        self.user = mastodonUser
//        self.domain = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value?.domain)
//        self.userID = CurrentValueSubject(mastodonUser?.id)
//        self.bannerImageURL = CurrentValueSubject(mastodonUser?.headerImageURL())
//        self.avatarImageURL = CurrentValueSubject(mastodonUser?.avatarImageURL())
//        self.name = CurrentValueSubject(mastodonUser?.displayNameWithFallback)
//        self.username = CurrentValueSubject(mastodonUser?.acctWithDomain)
//        self.bioDescription = CurrentValueSubject(mastodonUser?.note)
//        self.url = CurrentValueSubject(mastodonUser?.url)
//        self.statusesCount = CurrentValueSubject(mastodonUser.flatMap { Int($0.statusesCount) })
//        self.followingCount = CurrentValueSubject(mastodonUser.flatMap { Int($0.followingCount) })
//        self.followersCount = CurrentValueSubject(mastodonUser.flatMap { Int($0.followersCount) })
//        self.protected = CurrentValueSubject(mastodonUser?.locked)
//        self.suspended = CurrentValueSubject(mastodonUser?.suspended ?? false)
//        self.fields = CurrentValueSubject(mastodonUser?.fields ?? [])
//        self.emojiMeta = CurrentValueSubject(mastodonUser?.emojis.asDictionary ?? [:])
        self.postsUserTimelineViewModel = UserTimelineViewModel(
            context: context,
            queryFilter: .init(excludeReplies: true)
        )
        self.repliesUserTimelineViewModel = UserTimelineViewModel(
            context: context,
            queryFilter: .init(excludeReplies: true)
        )
        self.mediaUserTimelineViewModel = UserTimelineViewModel(
            context: context,
            queryFilter: .init(onlyMedia: true)
        )
        self.profileAboutViewModel = ProfileAboutViewModel(context: context)
        super.init()
        
        // bind me
        context.authenticationService.activeMastodonAuthenticationBox
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationBox in
                guard let self = self else { return }
                self.me = authenticationBox?.authenticationRecord.object(in: context.managedObjectContext)?.user
            }
            .store(in: &disposeBag)

        // bind user
        $user
            .map { user -> UserIdentifier? in
                guard let user = user else { return nil }
                return MastodonUserIdentifier(domain: user.domain, userID: user.id)
            }
            .assign(to: &$userIdentifier)
        
        $userIdentifier.assign(to: &postsUserTimelineViewModel.$userIdentifier)
        $userIdentifier.assign(to: &repliesUserTimelineViewModel.$userIdentifier)
        $userIdentifier.assign(to: &mediaUserTimelineViewModel.$userIdentifier)
        // $userIdentifier.assign(to: &profileAboutViewModel.$userIdentifier)
        
//        relationshipActionOptionSet
//            .compactMap { $0.highPriorityAction(except: []) }
//            .map { $0 == .none }
//            .assign(to: \.value, on: isRelationshipActionButtonHidden)
//            .store(in: &disposeBag)
//

//
//        // query relationship
//        let userRecord = $user.map { user -> ManagedObjectRecord<MastodonUser>? in
//            user.flatMap { ManagedObjectRecord<MastodonUser>(objectID: $0.objectID) }
//        }
//        let pendingRetryPublisher = CurrentValueSubject<TimeInterval, Never>(1)
//
//        // observe friendship
//        Publishers.CombineLatest3(
//            userRecord,
//            context.authenticationService.activeMastodonAuthenticationBox,
//            pendingRetryPublisher
//        )
//        .sink { [weak self] userRecord, authenticationBox, _ in
//            guard let self = self else { return }
//            guard let userRecord = userRecord,
//                  let authenticationBox = authenticationBox
//            else { return }
//            Task {
//                do {
//                    let response = try await self.updateRelationship(
//                        record: userRecord,
//                        authenticationBox: authenticationBox
//                    )
//                    // there are seconds delay after request follow before requested -> following. Query again when needs
//                    guard let relationship = response.value.first else { return }
//                    if relationship.requested == true {
//                        let delay = pendingRetryPublisher.value
//                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
//                            guard let _ = self else { return }
//                            pendingRetryPublisher.value = min(2 * delay, 60)
//                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] fetch again due to pending", ((#file as NSString).lastPathComponent), #line, #function)
//                        }
//                    }
//                } catch {
//                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship failure: \(error.localizedDescription)")
//                }
//            }
//        }
//        .store(in: &disposeBag)
//
//        let isBlockingOrBlocked = Publishers.CombineLatest(
//            isBlocking,
//            isBlockedBy
//        )
//        .map { $0 || $1 }
//        .share()
//
//        isBlockingOrBlocked
//            .map { !$0 }
//            .assign(to: \.value, on: needsPagingEnabled)
//            .store(in: &disposeBag)
//
//        isBlockingOrBlocked
//            .map { $0 }
//            .assign(to: \.value, on: needsImageOverlayBlurred)
//            .store(in: &disposeBag)
//
//        setup()
    }
    
}

extension ProfileViewModel {
    private func setup() {
        Publishers.CombineLatest(
            $user,
            $me
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] user, me in
            guard let self = self else { return }
            // Update view model attribute
            self.update(mastodonUser: user)
            self.update(mastodonUser: user, currentMastodonUser: me)

            // Setup observer for user
            if let mastodonUser = user {
                // setup observer
                self.mastodonUserObserver = ManagedObjectObserver.observe(object: mastodonUser)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            assertionFailure(error.localizedDescription)
                        case .finished:
                            assertionFailure()
                        }
                    } receiveValue: { [weak self] change in
                        guard let self = self else { return }
                        guard let changeType = change.changeType else { return }
                        switch changeType {
                        case .update:
                            self.update(mastodonUser: mastodonUser)
                            self.update(mastodonUser: mastodonUser, currentMastodonUser: me)
                        case .delete:
                            // TODO:
                            break
                        }
                    }

            } else {
                self.mastodonUserObserver = nil
            }

            // Setup observer for user
            if let currentMastodonUser = me {
                // setup observer
                self.currentMastodonUserObserver = ManagedObjectObserver.observe(object: currentMastodonUser)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            assertionFailure(error.localizedDescription)
                        case .finished:
                            assertionFailure()
                        }
                    } receiveValue: { [weak self] change in
                        guard let self = self else { return }
                        guard let changeType = change.changeType else { return }
                        switch changeType {
                        case .update:
                            self.update(mastodonUser: user, currentMastodonUser: currentMastodonUser)
                        case .delete:
                            // TODO:
                            break
                        }
                    }
            } else {
                self.currentMastodonUserObserver = nil
            }
        }
        .store(in: &disposeBag)
    }
    
    private func update(mastodonUser: MastodonUser?) {
//        self.userID.value = mastodonUser?.id
//        self.bannerImageURL.value = mastodonUser?.headerImageURL()
//        self.avatarImageURL.value = mastodonUser?.avatarImageURL()
//        self.name.value = mastodonUser?.displayNameWithFallback
//        self.username.value = mastodonUser?.acctWithDomain
//        self.bioDescription.value = mastodonUser?.note
//        self.url.value = mastodonUser?.url
//        self.statusesCount.value = mastodonUser.flatMap { Int($0.statusesCount) }
//        self.followingCount.value = mastodonUser.flatMap { Int($0.followingCount) }
//        self.followersCount.value = mastodonUser.flatMap { Int($0.followersCount) }
//        self.protected.value = mastodonUser?.locked
//        self.suspended.value = mastodonUser?.suspended ?? false
//        self.fields.value = mastodonUser?.fields ?? []
//        self.emojiMeta.value = mastodonUser?.emojis.asDictionary ?? [:]
    }
    
    private func update(mastodonUser: MastodonUser?, currentMastodonUser: MastodonUser?) {
//        guard let mastodonUser = mastodonUser,
//              let currentMastodonUser = currentMastodonUser else {
//            // set relationship
//            self.relationshipActionOptionSet.value = .none
//            self.isFollowedBy.value = false
//            self.isMuting.value = false
//            self.isBlocking.value = false
//            self.isBlockedBy.value = false
//
//            // set bar button item state
//            self.isReplyBarButtonItemHidden.value = true
//            self.isMoreMenuBarButtonItemHidden.value = true
//            self.isMeBarButtonItemsHidden.value = true
//            return
//        }
//
//        if mastodonUser == currentMastodonUser {
//            self.relationshipActionOptionSet.value = [.edit]
//            // set bar button item state
//            self.isReplyBarButtonItemHidden.value = true
//            self.isMoreMenuBarButtonItemHidden.value = true
//            self.isMeBarButtonItemsHidden.value = false
//        } else {
//            // set with follow action default
//            var relationshipActionSet = RelationshipActionOptionSet([.follow])
//
//            if mastodonUser.locked {
//                relationshipActionSet.insert(.request)
//            }
//
//            if mastodonUser.suspended {
//                relationshipActionSet.insert(.suspended)
//            }
//
//            let isFollowing = mastodonUser.followingBy.contains(currentMastodonUser)
//            if isFollowing {
//                relationshipActionSet.insert(.following)
//            }
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isFollowing: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isFollowing.description)
//
//            let isPending = mastodonUser.followRequestedBy.contains(currentMastodonUser)
//            if isPending {
//                relationshipActionSet.insert(.pending)
//            }
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isPending: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isPending.description)
//
//            let isFollowedBy = currentMastodonUser.followingBy.contains(mastodonUser)
//            self.isFollowedBy.value = isFollowedBy
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isFollowedBy: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isFollowedBy.description)
//
//            let isMuting = mastodonUser.mutingBy.contains(currentMastodonUser)
//            if isMuting {
//                relationshipActionSet.insert(.muting)
//            }
//            self.isMuting.value = isMuting
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isMuting: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isMuting.description)
//
//            let isBlocking = mastodonUser.blockingBy.contains(currentMastodonUser)
//            if isBlocking {
//                relationshipActionSet.insert(.blocking)
//            }
//            self.isBlocking.value = isBlocking
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isBlocking: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isBlocking.description)
//
//            let isBlockedBy = currentMastodonUser.blockingBy.contains(mastodonUser)
//            if isBlockedBy {
//                relationshipActionSet.insert(.blocked)
//            }
//            self.isBlockedBy.value = isBlockedBy
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isBlockedBy: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isBlockedBy.description)
//
//            self.relationshipActionOptionSet.value = relationshipActionSet
//
//            // set bar button item state
//            self.isReplyBarButtonItemHidden.value = isBlocking || isBlockedBy
//            self.isMoreMenuBarButtonItemHidden.value = false
//            self.isMeBarButtonItemsHidden.value = true
//        }
    }

}

extension ProfileViewModel {

    // fetch profile info before edit
    func fetchEditProfileInfo() -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        guard let me = me,
              let mastodonAuthentication = me.mastodonAuthentication
        else {
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }

        let authorization = Mastodon.API.OAuth.Authorization(accessToken: mastodonAuthentication.userAccessToken)
        return context.apiService.accountVerifyCredentials(domain: me.domain, authorization: authorization)
    }
    
    private func updateRelationship(
        record: ManagedObjectRecord<MastodonUser>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship...")
        let response = try await context.apiService.relationship(
            records: [record],
            authenticationBox: authenticationBox
        )
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] did update MastodonUser relationship")
        return response
    }

}

extension ProfileViewModel {
    func updateProfileInfo(
        headerProfileInfo: ProfileHeaderViewModel.ProfileInfo,
        aboutProfileInfo: ProfileAboutViewModel.ProfileInfo
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            throw APIService.APIError.implicit(.badRequest)
        }
        
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let _image: UIImage? = {
            guard let image = headerProfileInfo.avatarImage else { return nil }
            guard image.size.width <= ProfileHeaderViewModel.avatarImageMaxSizeInPixel.width else {
                return image.af.imageScaled(to: ProfileHeaderViewModel.avatarImageMaxSizeInPixel)
            }
            return image
        }()
        
        let fieldsAttributes = aboutProfileInfo.fields.map { field in
            Mastodon.Entity.Field(name: field.name.value, value: field.value.value)
        }
        
        let query = Mastodon.API.Account.UpdateCredentialQuery(
            discoverable: nil,
            bot: nil,
            displayName: headerProfileInfo.name,
            note: headerProfileInfo.note,
            avatar: _image.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: nil,
            locked: nil,
            source: nil,
            fieldsAttributes: fieldsAttributes
        )
        return try await context.apiService.accountUpdateCredentials(
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
}
