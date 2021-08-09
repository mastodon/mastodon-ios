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

final class SendPostIntentHandler: NSObject, SendPostIntentHandling {

    var disposeBag = Set<AnyCancellable>()

    lazy var coreDataStack = CoreDataStack()
    lazy var managedObjectContext = coreDataStack.persistentContainer.viewContext

    func handle(intent: SendPostIntent, completion: @escaping (SendPostIntentResponse) -> Void) {
        managedObjectContext.performAndWait {
            let request = MastodonAuthentication.sortedFetchRequest
            let authentications = (try? self.managedObjectContext.fetch(request)) ?? []
            let _authentication = authentications.sorted(by: { $0.activedAt > $1.activedAt }).first

            guard let authentication = _authentication else {
                let failureReason = APIService.APIError.implicit(.authenticationMissing).errorDescription ?? "Fail to Send Post"
                completion(SendPostIntentResponse.failure(failureReason: failureReason))
                return
            }

            let box = MastodonAuthenticationBox(
                domain: authentication.domain,
                userID: authentication.userID,
                appAuthorization: .init(accessToken: authentication.appAccessToken),
                userAuthorization: .init(accessToken: authentication.userAccessToken)
            )

            let visibility: Mastodon.Entity.Status.Visibility = {
                switch intent.visibility {
                case .unknown:          return .public
                case .public:           return .public
                case .followersOnly:    return .private
                }
            }()
            let query = Mastodon.API.Statuses.PublishStatusQuery(
                status: intent.content,
                mediaIDs: nil,
                pollOptions: nil,
                pollExpiresIn: nil,
                inReplyToID: nil,
                sensitive: nil,
                spoilerText: nil,
                visibility: visibility
            )
            
            let idempotencyKey = UUID().uuidString

            APIService.shared.publishStatus(
                domain: box.domain,
                idempotencyKey: idempotencyKey,
                query: query,
                mastodonAuthenticationBox: box
            )
            .sink { _completion in
                switch _completion {
                case .failure(let error):
                    let failureReason = error.localizedDescription
                    completion(SendPostIntentResponse.failure(failureReason: failureReason))
                case .finished:
                    break
                }
            } receiveValue: { response in
                let post = Post(identifier: response.value.id, display: intent.content ?? "")
                post.url = URL(string: response.value.url ?? response.value.uri)
                let result = SendPostIntentResponse(code: .success, userActivity: nil)
                result.post = post
                completion(result)
            }
            .store(in: &disposeBag)
        }

    }

    func resolveContent(for intent: SendPostIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let content = intent.content, !content.isEmpty else {
            completion(.needsValue())
            return
        }

        completion(.success(with: content))
    }

    func resolveVisibility(for intent: SendPostIntent, with completion: @escaping (PostVisibilityResolutionResult) -> Void) {
        completion(.success(with: intent.visibility))
    }



}
