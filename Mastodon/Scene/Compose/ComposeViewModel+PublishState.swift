//
//  ComposeViewModel+PublishState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import GameplayKit
import MastodonSDK

//extension ComposeViewModel {
//    class PublishState: GKState {
//        weak var viewModel: ComposeViewModel?
//
//        init(viewModel: ComposeViewModel) {
//            self.viewModel = viewModel
//        }
//
//        override func didEnter(from previousState: GKState?) {
//            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
//            viewModel?.publishStateMachinePublisher.value = self
//        }
//    }
//}

//extension ComposeViewModel.PublishState {
//    class Initial: ComposeViewModel.PublishState {
//        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//            return stateClass == Publishing.self
//        }
//    }
//    
//    class Publishing: ComposeViewModel.PublishState {
//        
//        var publishingSubscription: AnyCancellable?
//        
//        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//            return stateClass == Fail.self || stateClass == Finish.self
//        }
//        
//        override func didEnter(from previousState: GKState?) {
//            super.didEnter(from: previousState)
//            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
//            
//            viewModel.updatePublishDate()
//            
//            let authenticationBox = viewModel.authenticationBox
//            let domain = authenticationBox.domain
//            let attachmentServices = viewModel.attachmentServices
//            let mediaIDs = attachmentServices.compactMap { attachmentService in
//                attachmentService.attachment.value?.id
//            }
//            let pollOptions: [String]? = {
//                guard viewModel.isPollComposing else { return nil }
//                return viewModel.pollOptionAttributes.map { attribute in attribute.option.value }
//            }()
//            let pollExpiresIn: Int? = {
//                guard viewModel.isPollComposing else { return nil }
//                return viewModel.pollExpiresOptionAttribute.expiresOption.value.seconds
//            }()
//            let inReplyToID: Mastodon.Entity.Status.ID? = {
//                guard case let .reply(status) = viewModel.composeKind else { return nil }
//                var id: Mastodon.Entity.Status.ID?
//                viewModel.context.managedObjectContext.performAndWait {
//                    guard let replyTo = status.object(in: viewModel.context.managedObjectContext) else { return }
//                    id = replyTo.id
//                }
//                return id
//            }()
//            let sensitive: Bool = viewModel.isContentWarningComposing
//            let spoilerText: String? = {
//                let text = viewModel.composeStatusAttribute.contentWarningContent.trimmingCharacters(in: .whitespacesAndNewlines)
//                guard !text.isEmpty else {
//                    return nil
//                }
//                return text
//            }()
//            let visibility = viewModel.selectedStatusVisibility.visibility
//            
//            let updateMediaQuerySubscriptions: [AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error>] = {
//                var subscriptions: [AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error>] = []
//                for attachmentService in attachmentServices {
//                    guard let attachmentID = attachmentService.attachment.value?.id else { continue }
//                    let description = attachmentService.description.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//                    guard !description.isEmpty else { continue }
//                    let query = Mastodon.API.Media.UpdateMediaQuery(
//                        file: nil,
//                        thumbnail: nil,
//                        description: description,
//                        focus: nil
//                    )
//                    let subscription = viewModel.context.apiService.updateMedia(
//                        domain: domain,
//                        attachmentID: attachmentID,
//                        query: query,
//                        mastodonAuthenticationBox: authenticationBox
//                    )
//                    subscriptions.append(subscription)
//                }
//                return subscriptions
//            }()
//            
//            let idempotencyKey = viewModel.idempotencyKey.value
//            
//            publishingSubscription = Publishers.MergeMany(updateMediaQuerySubscriptions)
//                .collect()
//                .asyncMap { attachments -> Mastodon.Response.Content<Mastodon.Entity.Status> in
//                    let query = Mastodon.API.Statuses.PublishStatusQuery(
//                        status: viewModel.composeStatusAttribute.composeContent,
//                        mediaIDs: mediaIDs.isEmpty ? nil : mediaIDs,
//                        pollOptions: pollOptions,
//                        pollExpiresIn: pollExpiresIn,
//                        inReplyToID: inReplyToID,
//                        sensitive: sensitive,
//                        spoilerText: spoilerText,
//                        visibility: visibility
//                    )
//                    return try await viewModel.context.apiService.publishStatus(
//                        domain: domain,
//                        idempotencyKey: idempotencyKey,
//                        query: query,
//                        authenticationBox: authenticationBox
//                    )
//                }
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: publish status %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                        stateMachine.enter(Fail.self)
//                    case .finished:
//                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: publish status success", ((#file as NSString).lastPathComponent), #line, #function)
//                        stateMachine.enter(Finish.self)
//                    }
//                } receiveValue: { response in
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: status %s published: %s", ((#file as NSString).lastPathComponent), #line, #function, response.value.id, response.value.uri)
//                }
//        }
//    }
//    
//    class Fail: ComposeViewModel.PublishState {
//        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//            // allow discard publishing
//            return stateClass == Publishing.self || stateClass == Discard.self
//        }
//    }
//    
//    class Discard: ComposeViewModel.PublishState {
//        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//            return false
//        }
//    }
//    
//    class Finish: ComposeViewModel.PublishState {
//        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//            return false
//        }
//    }
//
//}
