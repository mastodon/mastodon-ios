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
import MastodonCore
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
    let authContext: AuthContext
    @Published var me: MastodonUser?
    @Published var user: MastodonUser?
    
    let viewDidAppear = PassthroughSubject<Void, Never>()
    
    @Published var isEditing = false
    @Published var isUpdating = false
    @Published var accountForEdit: Mastodon.Entity.Account?
        
    // output
    let relationshipViewModel = RelationshipViewModel()
    
    @Published var userIdentifier: UserIdentifier? = nil
    
    @Published var isRelationshipActionButtonHidden: Bool = true
    @Published var isReplyBarButtonItemHidden: Bool = true
    @Published var isMoreMenuBarButtonItemHidden: Bool = true
    @Published var isMeBarButtonItemsHidden: Bool = true
    @Published var isPagingEnabled = true

    // @Published var protected: Bool? = nil
    // let needsPagePinToTop = CurrentValueSubject<Bool, Never>(false)
    
    init(context: AppContext, authContext: AuthContext, optionalMastodonUser mastodonUser: MastodonUser?) {
        self.context = context
        self.authContext = authContext
        self.user = mastodonUser
        self.postsUserTimelineViewModel = UserTimelineViewModel(
            context: context,
            authContext: authContext,
            title: L10n.Scene.Profile.SegmentedControl.posts,
            queryFilter: .init(excludeReplies: true)
        )
        self.repliesUserTimelineViewModel = UserTimelineViewModel(
            context: context,
            authContext: authContext,
            title: L10n.Scene.Profile.SegmentedControl.postsAndReplies,
            queryFilter: .init(excludeReplies: false)
        )
        self.mediaUserTimelineViewModel = UserTimelineViewModel(
            context: context,
            authContext: authContext,
            title: L10n.Scene.Profile.SegmentedControl.media,
            queryFilter: .init(onlyMedia: true)
        )
        self.profileAboutViewModel = ProfileAboutViewModel(context: context)
        super.init()
        
        // bind me
        self.me = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)?.user
        $me
            .assign(to: \.me, on: relationshipViewModel)
            .store(in: &disposeBag)

        // bind user
        $user
            .map { user -> UserIdentifier? in
                guard let user = user else { return nil }
                return MastodonUserIdentifier(domain: user.domain, userID: user.id)
            }
            .assign(to: &$userIdentifier)
        $user
            .assign(to: \.user, on: relationshipViewModel)
            .store(in: &disposeBag)
        
        // bind userIdentifier
        $userIdentifier.assign(to: &postsUserTimelineViewModel.$userIdentifier)
        $userIdentifier.assign(to: &repliesUserTimelineViewModel.$userIdentifier)
        $userIdentifier.assign(to: &mediaUserTimelineViewModel.$userIdentifier)
        
        // bind bar button items
        relationshipViewModel.$optionSet
            .sink { [weak self] optionSet in
                guard let self = self else { return }
                guard let optionSet = optionSet, !optionSet.contains(.none) else {
                    self.isReplyBarButtonItemHidden = true
                    self.isMoreMenuBarButtonItemHidden = true
                    self.isMeBarButtonItemsHidden = true
                    return
                }
                
                let isMyself = optionSet.contains(.isMyself)
                self.isReplyBarButtonItemHidden = isMyself
                self.isMoreMenuBarButtonItemHidden = isMyself
                self.isMeBarButtonItemsHidden = !isMyself
            }
            .store(in: &disposeBag)

        // query relationship
        let userRecord = $user.map { user -> ManagedObjectRecord<MastodonUser>? in
            user.flatMap { ManagedObjectRecord<MastodonUser>(objectID: $0.objectID) }
        }
        let pendingRetryPublisher = CurrentValueSubject<TimeInterval, Never>(1)

        // observe friendship
        Publishers.CombineLatest(
            userRecord,
            pendingRetryPublisher
        )
        .sink { [weak self] userRecord, _ in
            guard let self = self else { return }
            guard let userRecord = userRecord else { return }
            Task {
                do {
                    let response = try await self.updateRelationship(
                        record: userRecord,
                        authenticationBox: self.authContext.mastodonAuthenticationBox
                    )
                    // there are seconds delay after request follow before requested -> following. Query again when needs
                    guard let relationship = response.value.first else { return }
                    if relationship.requested == true {
                        let delay = pendingRetryPublisher.value
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                            guard let _ = self else { return }
                            pendingRetryPublisher.value = min(2 * delay, 60)
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] fetch again due to pending", ((#file as NSString).lastPathComponent), #line, #function)
                        }
                    }
                } catch {
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship failure: \(error.localizedDescription)")
                }
            }   // end Task
        }
        .store(in: &disposeBag)

        let isBlockingOrBlocked = Publishers.CombineLatest(
            relationshipViewModel.$isBlocking,
            relationshipViewModel.$isBlockingBy
        )
        .map { $0 || $1 }
        .share()
        
        Publishers.CombineLatest(
            isBlockingOrBlocked,
            $isEditing
        )
        .map { !$0 && !$1 }
        .assign(to: &$isPagingEnabled)
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
        let authenticationBox = authContext.mastodonAuthenticationBox
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        // TODO: constrain size?
        let _header: UIImage? = {
            guard let image = headerProfileInfo.header else { return nil }
            guard image.size.width <= ProfileHeaderViewModel.bannerImageMaxSizeInPixel.width else {
                return image.af.imageScaled(to: ProfileHeaderViewModel.bannerImageMaxSizeInPixel)
            }
            return image
        }()

        let _avatar: UIImage? = {
            guard let image = headerProfileInfo.avatar else { return nil }
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
            avatar: _avatar.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: _header.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
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
