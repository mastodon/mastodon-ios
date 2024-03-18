//
//  AuthenticationService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

private typealias IterativeResponse = (ids: [String], maxID: String?)

public final class AuthenticationService: NSObject {

    var disposeBag = Set<AnyCancellable>()
    
    // input
    weak var apiService: APIService?
    let managedObjectContext: NSManagedObjectContext    // read-only
    let backgroundManagedObjectContext: NSManagedObjectContext
    let authenticationServiceProvider = AuthenticationServiceProvider.shared

    // output
    @Published public var mastodonAuthenticationBoxes: [MastodonAuthenticationBox] = []

    private func fetchFollowedBlockedUserIds(
        _ authBox: MastodonAuthenticationBox,
        _ previousFollowingIDs: [String]? = nil,
        _ maxID: String? = nil
    ) async throws {
        guard let apiService else { return }
        
        let followingResponse = try await fetchFollowing(maxID, apiService, authBox)
        let followingIds = (previousFollowingIDs ?? []) + followingResponse.ids

        if let nextMaxID = followingResponse.maxID {
            return try await fetchFollowedBlockedUserIds(authBox, followingIds, nextMaxID)
        }
        
        let blockedIds = try await apiService.getBlocked(
            authenticationBox: authBox
        ).value.map { $0.id }

        let followRequestIds = try await apiService.pendingFollowRequest(userID: authBox.userID,
                                                                         authenticationBox: authBox)
            .value.map { $0.id }

        authBox.inMemoryCache.followRequestedUserIDs = followRequestIds
        authBox.inMemoryCache.followingUserIds = followingIds
        authBox.inMemoryCache.blockedUserIds = blockedIds
    }

    private func fetchFollowing(
        _ maxID: String?,
        _ apiService: APIService,
        _ mastodonAuthenticationBox: MastodonAuthenticationBox
    ) async throws -> IterativeResponse {
        let response = try await apiService.following(
            userID: mastodonAuthenticationBox.userID,
            maxID: maxID,
            authenticationBox: mastodonAuthenticationBox
        )
        
        let ids: [String] = response.value.map { $0.id }
        let maxID: String? = response.link?.maxID
        
        return (ids, maxID)
    }
    
    public func fetchFollowingAndBlockedAsync() {
        /// We're dispatching this as a separate async call to not block the caller
        /// Also we'll only be updating the current active user as the state will be reflesh upon user-change anyways
        Task {
            if let authBox = mastodonAuthenticationBoxes.first {
                do { try await fetchFollowedBlockedUserIds(authBox) }
                catch {}
            }
        }
    }
    
    public let updateActiveUserAccountPublisher = PassthroughSubject<Void, Never>()

    init(
        managedObjectContext: NSManagedObjectContext,
        backgroundManagedObjectContext: NSManagedObjectContext,
        apiService: APIService
    ) {
        self.managedObjectContext = managedObjectContext
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.apiService = apiService

        super.init()
        
        $mastodonAuthenticationBoxes
            .throttle(for: 3, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] boxes in
                Task { [weak self] in
                    for authBox in boxes {
                        do { try await self?.fetchFollowedBlockedUserIds(authBox) }
                        catch {}
                    }
                }
            }
            .store(in: &disposeBag)
        

        // TODO: verify credentials for active authentication
        
        authenticationServiceProvider.$authentications
            .map { authentications -> [MastodonAuthenticationBox] in
                return authentications
                    .sorted(by: { $0.activedAt > $1.activedAt })
                    .compactMap { authentication -> MastodonAuthenticationBox? in
                        return MastodonAuthenticationBox(authentication: authentication)
                    }
            }
            .assign(to: &$mastodonAuthenticationBoxes)
    
        AuthenticationServiceProvider.shared.authentications = AuthenticationServiceProvider.shared.authenticationSortedByActivation()
    }

}

extension AuthenticationService {
    
    public func activeMastodonUser(domain: String, userID: String) async throws -> Bool {
        var isActive = false
        
        AuthenticationServiceProvider.shared.activateAuthentication(in: domain, for: userID)
        
        isActive = true
        
        return isActive
    }
    
    public func signOutMastodonUser(authenticationBox: MastodonAuthenticationBox) async throws {
        do {
            try AuthenticationServiceProvider.shared.delete(authentication: authenticationBox.authentication)
        } catch {
            assertionFailure("Failed to delete Authentication: \(error)")
        }
        
        // cancel push notification subscription
        do {
            _ = try await apiService?.cancelSubscription(
                domain: authenticationBox.domain,
                authorization: authenticationBox.userAuthorization
            )
        } catch {
            // do nothing
        }
    }
    
}
