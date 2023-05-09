//
//  AuthenticationService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import os.log
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
    let mastodonAuthenticationFetchedResultsController: NSFetchedResultsController<MastodonAuthentication>

    // output
    @Published public var mastodonAuthentications: [ManagedObjectRecord<MastodonAuthentication>] = []
    @Published public var mastodonAuthenticationBoxes: [MastodonAuthenticationBox] = []
    
    private func fetchFollowedBlockedUserIds(
        _ authBox: MastodonAuthenticationBox,
        _ previousFollowingIDs: [String]? = nil,
        _ maxID: String? = nil
    ) async throws {
        guard let apiService = apiService else { return }
        
        let followingResponse = try await fetchFollowing(maxID, apiService, authBox)
        let followingIds = (previousFollowingIDs ?? []) + followingResponse.ids

        if let nextMaxID = followingResponse.maxID {
            return try await fetchFollowedBlockedUserIds(authBox, followingIds, nextMaxID)
        }
        
        let blockedIds = try await apiService.getBlocked(
            authenticationBox: authBox
        ).value.map { $0.id }
        
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
        /// we're dispatching this as a separate async call to not block the caller
        Task {
            for authBox in mastodonAuthenticationBoxes {
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
        self.mastodonAuthenticationFetchedResultsController = {
            let fetchRequest = MastodonAuthentication.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            return controller
        }()
        super.init()

        mastodonAuthenticationFetchedResultsController.delegate = self
        
        $mastodonAuthenticationBoxes
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
        
        $mastodonAuthentications
            .map { authentications -> [MastodonAuthenticationBox] in
                return authentications
                    .compactMap { $0.object(in: managedObjectContext) }
                    .sorted(by: { $0.activedAt > $1.activedAt })
                    .compactMap { authentication -> MastodonAuthenticationBox? in
                        return MastodonAuthenticationBox(authentication: authentication)
                    }
            }
            .assign(to: &$mastodonAuthenticationBoxes)
    
        do {
            try mastodonAuthenticationFetchedResultsController.performFetch()
            mastodonAuthentications = mastodonAuthenticationFetchedResultsController.fetchedObjects?
                .sorted(by: { $0.activedAt > $1.activedAt })
                .compactMap { $0.asRecord } ?? []
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

}

extension AuthenticationService {
    
    public func activeMastodonUser(domain: String, userID: MastodonUser.ID) async throws -> Bool {
        var isActive = false
        
        let managedObjectContext = backgroundManagedObjectContext

        try await managedObjectContext.performChanges {
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain, userID: userID)
            request.fetchLimit = 1
            guard let mastodonAuthentication = try? managedObjectContext.fetch(request).first else {
                return
            }
            mastodonAuthentication.update(activedAt: Date())
            isActive = true
        }
        
        return isActive
    }
    
    public func signOutMastodonUser(authenticationBox: MastodonAuthenticationBox) async throws {
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            // remove Feed
            let request = Feed.sortedFetchRequest
            request.predicate = Feed.predicate(
                acct: .mastodon(
                    domain: authenticationBox.domain,
                    userID: authenticationBox.userID
                )
            )
            let feeds = managedObjectContext.safeFetch(request)
            for feed in feeds {
                managedObjectContext.delete(feed)
            }
            
            guard let authentication = authenticationBox.authenticationRecord.object(in: managedObjectContext) else {
                assertionFailure()
                throw APIService.APIError.implicit(.authenticationMissing)
            }
            
            managedObjectContext.delete(authentication)
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

// MARK: - NSFetchedResultsControllerDelegate
extension AuthenticationService: NSFetchedResultsControllerDelegate {
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard controller === mastodonAuthenticationFetchedResultsController else {
            assertionFailure()
            return
        }
    
        mastodonAuthentications = mastodonAuthenticationFetchedResultsController.fetchedObjects?
            .sorted(by: { $0.activedAt > $1.activedAt })
            .compactMap { $0.asRecord } ?? []
    }
    
}
