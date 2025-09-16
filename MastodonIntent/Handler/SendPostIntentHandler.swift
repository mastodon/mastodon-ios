//
//  SendPostIntentHandler.swift
//  MastodonIntent
//
//  Created by Cirno MainasuK on 2021-7-26.
//

import Foundation
import Intents
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore

@MainActor
final class SendPostIntentHandler: NSObject {

    var disposeBag = Set<AnyCancellable>()

    let coreDataStack = CoreDataStack()
    lazy var managedObjectContext = coreDataStack.persistentContainer.viewContext
    lazy var api: APIService = {
        return APIService.isolatedService()
    }()
}

// MARK: - SendPostIntentHandling
extension SendPostIntentHandler: SendPostIntentHandling {

    func handle(intent: SendPostIntent) async -> SendPostIntentResponse {
        guard let content = intent.content else {
            return SendPostIntentResponse(code: .failure, userActivity: nil)
        }
        
        let visibility: Mastodon.Entity.Status.Visibility = {
            switch intent.visibility {
            case .unknown:          return .public
            case .public:           return .public
            case .followersOnly:    return .private
            }
        }()
        
        do {
            // fetch authentications from
            // user pick accounts
            // or fallback to active account
            let authBoxes: [MastodonAuthenticationBox]
            let accounts = intent.accounts ?? []
            if accounts.isEmpty {
                guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else {
                    let failureReason = APIService.APIError.implicit(.authenticationMissing).errorDescription ?? "Fail to Send Post"
                    return SendPostIntentResponse.failure(failureReason: failureReason)
                }
                authBoxes = [authBox]
            } else {
                authBoxes = try accounts.mastodonAuthenticationBoxes()
            }
            
            var posts: [Post] = []
            for authenticationBox in authBoxes {
                let idempotencyKey = UUID().uuidString
                let response = try await api.publishStatus(
                    domain: authenticationBox.domain,
                    idempotencyKey: idempotencyKey,
                    query: .init(
                        status: content,
                        mediaIDs: nil,
                        pollOptions: nil,
                        pollExpiresIn: nil,
                        inReplyToID: nil,
                        quotingID: nil,
                        sensitive: nil,
                        spoilerText: nil,
                        visibility: visibility,
                        quotePolicy: .nobody,  // TODO: update intents to include quotability
                        language: nil
                    ),
                    authenticationBox: authenticationBox
                )
                let post = Post(
                    identifier: response.value.id,
                    display: response.value.account.acct,
                    subtitle: content,
                    image: response.value.account.avatarImageURL().flatMap { INImage(url: $0) }
                )
                if let urlString = response.value.url, let url = URL(string: urlString) {
                    post.url = url
                }
                posts.append(post)
            }   // end for in

            let intentResponse = SendPostIntentResponse(code: .success, userActivity: nil)
            intentResponse.posts = posts
            
            return intentResponse
        } catch {
            let intentResponse = SendPostIntentResponse(code: .failure, userActivity: nil)
            if let error = error as? LocalizedError {
                intentResponse.failureReason = [
                    error.errorDescription,
                    error.failureReason,
                    error.recoverySuggestion
                ]
                .compactMap { $0 }
                .joined(separator: ", ")
            } else {
                intentResponse.failureReason = error.localizedDescription
            }
            return intentResponse
        }
    }   // end func

    // content
    nonisolated func resolveContent(for intent: SendPostIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let content = intent.content, !content.isEmpty else {
            completion(.needsValue())
            return
        }

        completion(.success(with: content))
    }
    
    // accounts
    func resolveAccounts(for intent: SendPostIntent) async -> [AccountResolutionResult] {
        guard let accounts = intent.accounts, !accounts.isEmpty else {
            return [AccountResolutionResult.needsValue()]
        }
        
        let results = accounts.map { account in
            AccountResolutionResult.success(with: account)
        }
        
        return results
    }
    
    func provideAccountsOptionsCollection(for intent: SendPostIntent) async throws -> INObjectCollection<Account> {
        let accounts = Account.loadFromCache()
        return .init(items: accounts)
    }

    // visibility
    nonisolated func resolveVisibility(for intent: SendPostIntent, with completion: @escaping (PostVisibilityResolutionResult) -> Void) {
        completion(.success(with: intent.visibility))
    }

}

extension Array where Element == Account {
    @MainActor
    func mastodonAuthenticationBoxes() throws -> [MastodonAuthenticationBox] {
        let identifiers = self
            .compactMap { $0.identifier }
            .compactMap { UUID(uuidString: $0) }
        let results = AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.filter({ identifiers.contains($0.authentication.identifier) })
        return results
    }

}
