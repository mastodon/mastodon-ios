//
//  ProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

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

    @Published var me: Mastodon.Entity.Account
    @Published var account: Mastodon.Entity.Account
    @Published var relationship: Mastodon.Entity.Relationship?

    let viewDidAppear = PassthroughSubject<Void, Never>()
    
    @Published var isEditing = false
    @Published var isUpdating = false
    @Published var accountForEdit: Mastodon.Entity.Account?
        
    @Published var userIdentifier: UserIdentifier? = nil
    
    @Published var isReplyBarButtonItemHidden: Bool = true
    @Published var isMoreMenuBarButtonItemHidden: Bool = true
    @Published var isMeBarButtonItemsHidden: Bool = true
    @Published var isPagingEnabled = true

    // @Published var protected: Bool? = nil
    // let needsPagePinToTop = CurrentValueSubject<Bool, Never>(false)
    
    @MainActor
    init(context: AppContext, authContext: AuthContext, account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?, me: Mastodon.Entity.Account) {
        self.context = context
        self.authContext = authContext
        self.account = account
        self.relationship = relationship
        self.me = me

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
        self.profileAboutViewModel = ProfileAboutViewModel(context: context, account: account)
        super.init()

        if let domain = account.domain {
            userIdentifier = MastodonUserIdentifier(domain: domain, userID: account.id)
        } else {
            userIdentifier = nil
        }

        // bind userIdentifier
        $userIdentifier.assign(to: &postsUserTimelineViewModel.$userIdentifier)
        $userIdentifier.assign(to: &repliesUserTimelineViewModel.$userIdentifier)
        $userIdentifier.assign(to: &mediaUserTimelineViewModel.$userIdentifier)
        
        // bind bar button items
        Publishers.CombineLatest3($account, $me, $relationship)
            .sink(receiveValue: { [weak self] account, me, relationship in
                guard let self else {
                    self?.isReplyBarButtonItemHidden = true
                    self?.isMoreMenuBarButtonItemHidden = true
                    self?.isMeBarButtonItemsHidden = true
                    return
                }

                let isMyself = (account == me)
                self.isReplyBarButtonItemHidden = isMyself
                self.isMoreMenuBarButtonItemHidden = isMyself
                self.isMeBarButtonItemsHidden = (isMyself == false)
            })
            .store(in: &disposeBag)

        viewDidAppear
            .sink { [weak self] _ in
                guard let self else { return }

                self.isReplyBarButtonItemHidden = self.isReplyBarButtonItemHidden
                self.isMoreMenuBarButtonItemHidden = self.isMoreMenuBarButtonItemHidden
                self.isMeBarButtonItemsHidden = self.isMeBarButtonItemsHidden
            }
            .store(in: &disposeBag)
        // query relationship

        let pendingRetryPublisher = CurrentValueSubject<TimeInterval, Never>(1)

        // observe friendship
        Publishers.CombineLatest(
            $account,
            pendingRetryPublisher
        )
        .sink { [weak self] account, _ in
            guard let self else { return }

            Task {
                do {
                    let response = try await self.context.apiService.relationship(
                        forAccounts: [account],
                        authenticationBox: self.authContext.mastodonAuthenticationBox
                    )

                    // there are seconds delay after request follow before requested -> following. Query again when needs
                    guard let relationship = response.value.first else { return }
                    if relationship.requested == true {
                        let delay = pendingRetryPublisher.value
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                            guard let _ = self else { return }
                            pendingRetryPublisher.value = min(2 * delay, 60)
                        }
                    }
                } catch {
                }
            }   // end Task
        }
        .store(in: &disposeBag)

        let isBlockingOrBlocked = Publishers.CombineLatest3(
            (relationship?.blocking ?? false).publisher,
            (relationship?.blockedBy ?? false).publisher,
            (relationship?.domainBlocking ?? false).publisher
        )
        .map { $0 || $1 || $2 }
        .share()
        
        Publishers.CombineLatest(
            isBlockingOrBlocked,
            $isEditing
        )
        .map { !$0 && !$1 }
        .assign(to: &$isPagingEnabled)
    }
    
    // fetch profile info before edit
    func fetchEditProfileInfo() -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        guard let domain = me.domain else {
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }

        let mastodonAuthentication = authContext.mastodonAuthenticationBox.authentication
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: mastodonAuthentication.userAccessToken)
        return context.apiService.accountVerifyCredentials(domain: domain, authorization: authorization)
            .tryMap { response in
                FileManager.default.store(account: response.value, forUserID: mastodonAuthentication.userIdentifier())
                return response
            }.eraseToAnyPublisher()
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
        let response = try await context.apiService.accountUpdateCredentials(
            domain: domain,
            query: query,
            authorization: authorization
        )

        FileManager.default.store(account: response.value, forUserID: authenticationBox.authentication.userIdentifier())
        NotificationCenter.default.post(name: .userFetched, object: nil)

        return response
    }
}
