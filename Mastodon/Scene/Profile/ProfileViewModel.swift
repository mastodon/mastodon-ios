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

// please override this base class
class ProfileViewModel: NSObject {
    
    typealias UserID = String
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private var mastodonUserObserver: AnyCancellable?
    private var currentMastodonUserObserver: AnyCancellable?
    
    // input
    let context: AppContext
    let mastodonUser: CurrentValueSubject<MastodonUser?, Never>
    let currentMastodonUser = CurrentValueSubject<MastodonUser?, Never>(nil)
    let viewDidAppear = PassthroughSubject<Void, Never>()
    let headerDomainLumaStyle = CurrentValueSubject<UIUserInterfaceStyle, Never>(.dark) // default dark for placeholder banner
        
    // output
    let domain: CurrentValueSubject<String?, Never>
    let userID: CurrentValueSubject<UserID?, Never>
    let bannerImageURL: CurrentValueSubject<URL?, Never>
    let avatarImageURL: CurrentValueSubject<URL?, Never>
//    let protected: CurrentValueSubject<Bool?, Never>
    let name: CurrentValueSubject<String?, Never>
    let username: CurrentValueSubject<String?, Never>
    let bioDescription: CurrentValueSubject<String?, Never>
    let url: CurrentValueSubject<String?, Never>
    let statusesCount: CurrentValueSubject<Int?, Never>
    let followingCount: CurrentValueSubject<Int?, Never>
    let followersCount: CurrentValueSubject<Int?, Never>

//    let friendship: CurrentValueSubject<Friendship?, Never>
//    let followedBy: CurrentValueSubject<Bool?, Never>
//    let muted: CurrentValueSubject<Bool, Never>
//    let blocked: CurrentValueSubject<Bool, Never>
//
//    let suspended = CurrentValueSubject<Bool, Never>(false)
//
    
    init(context: AppContext, optionalMastodonUser mastodonUser: MastodonUser?) {
        self.context = context
        self.mastodonUser = CurrentValueSubject(mastodonUser)
        self.domain = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value?.domain)
        self.userID = CurrentValueSubject(mastodonUser?.id)
        self.bannerImageURL = CurrentValueSubject(mastodonUser?.headerImageURL())
        self.avatarImageURL = CurrentValueSubject(mastodonUser?.avatarImageURL())
//        self.protected = CurrentValueSubject(twitterUser?.protected)
        self.name = CurrentValueSubject(mastodonUser?.displayNameWithFallback)
        self.username = CurrentValueSubject(mastodonUser?.acctWithDomain)
        self.bioDescription = CurrentValueSubject(mastodonUser?.note)
        self.url = CurrentValueSubject(mastodonUser?.url)
        self.statusesCount = CurrentValueSubject(mastodonUser.flatMap { Int(truncating: $0.statusesCount) })
        self.followingCount = CurrentValueSubject(mastodonUser.flatMap { Int(truncating: $0.followingCount) })
        self.followersCount = CurrentValueSubject(mastodonUser.flatMap { Int(truncating: $0.followersCount) })
//        self.friendship = CurrentValueSubject(nil)
//        self.followedBy = CurrentValueSubject(nil)
//        self.muted = CurrentValueSubject(false)
//        self.blocked = CurrentValueSubject(false)
        super.init()

        // bind active authentication
        context.authenticationService.activeMastodonAuthentication
            .sink { [weak self] activeMastodonAuthentication in
                guard let self = self else { return }
                guard let activeMastodonAuthentication = activeMastodonAuthentication else {
                    self.domain.value = nil
                    self.currentMastodonUser.value = nil
                    return
                }
                self.domain.value = activeMastodonAuthentication.domain
                self.currentMastodonUser.value = activeMastodonAuthentication.user
            }
            .store(in: &disposeBag)

        setup()
    }
    
}

extension ProfileViewModel {
    
    enum Friendship: CustomDebugStringConvertible {
        case following
        case pending
        case none
        
        var debugDescription: String {
            switch self {
            case .following:        return "following"
            case .pending:          return "pending"
            case .none:             return "none"
            }
        }
    }
    
}

extension ProfileViewModel {
    private func setup() {
        Publishers.CombineLatest(
            mastodonUser.eraseToAnyPublisher(),
            currentMastodonUser.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] mastodonUser, currentMastodonUser in
            guard let self = self else { return }
            self.update(mastodonUser: mastodonUser)
            self.update(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)

            if let mastodonUser = mastodonUser {
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
                            self.update(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)
                        case .delete:
                            // TODO:
                            break
                        }
                    }

            } else {
                self.mastodonUserObserver = nil
            }

            if let currentMastodonUser = currentMastodonUser {
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
                            self.update(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)
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
        self.userID.value = mastodonUser?.id
        self.bannerImageURL.value = mastodonUser?.headerImageURL()
        self.avatarImageURL.value = mastodonUser?.avatarImageURL()
//        self.protected.value = twitterUser?.protected
        self.name.value = mastodonUser?.displayNameWithFallback
        self.username.value = mastodonUser?.acctWithDomain
        self.bioDescription.value = mastodonUser?.note
        self.url.value = mastodonUser?.url
        self.statusesCount.value = mastodonUser.flatMap { Int(truncating: $0.statusesCount) }
        self.followingCount.value = mastodonUser.flatMap { Int(truncating: $0.followingCount) }
        self.followersCount.value = mastodonUser.flatMap { Int(truncating: $0.followersCount) }
    }
    
    private func update(mastodonUser: MastodonUser?, currentMastodonUser: MastodonUser?) {
        // TODO:
    }

    
}
