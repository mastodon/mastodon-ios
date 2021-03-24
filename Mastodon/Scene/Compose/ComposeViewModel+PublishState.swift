//
//  ComposeViewModel+PublishState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import os.log
import Foundation
import Combine
import GameplayKit
import MastodonSDK

extension ComposeViewModel {
    class PublishState: GKState {
        weak var viewModel: ComposeViewModel?
        
        init(viewModel: ComposeViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension ComposeViewModel.PublishState {
    class Initial: ComposeViewModel.PublishState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Publishing.self
        }
    }
    
    class Publishing: ComposeViewModel.PublishState {
        
        var publishingSubscription: AnyCancellable?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Finish.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let mastodonAuthenticationBox = viewModel.activeAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let domain = mastodonAuthenticationBox.domain
            let attachmentServices = viewModel.attachmentServices.value
            let mediaIDs = attachmentServices.compactMap { attachmentService in
                attachmentService.attachment.value?.id
            }
            let pollOptions: [String]? = {
                guard viewModel.isPollComposing.value else { return nil }
                return viewModel.pollAttributes.value.map { attribute in attribute.option.value }
            }()
            let pollExpiresIn: Int? = {
                guard viewModel.isPollComposing.value else { return nil }
                return viewModel.pollExpiresOptionAttribute.expiresOption.value.seconds
            }()
            
            let updateMediaQuerySubscriptions: [AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error>] = {
                var subscriptions: [AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Attachment>, Error>] = []
                for attachmentService in attachmentServices {
                    guard let attachmentID = attachmentService.attachment.value?.id else { continue }
                    let description = attachmentService.description.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    guard !description.isEmpty else { continue }
                    let query = Mastodon.API.Media.UpdateMediaQuery(
                        file: nil,
                        thumbnail: nil,
                        description: description,
                        focus: nil
                    )
                    let subscription = viewModel.context.apiService.updateMedia(
                        domain: domain,
                        attachmentID: attachmentID,
                        query: query,
                        mastodonAuthenticationBox: mastodonAuthenticationBox
                    )
                    subscriptions.append(subscription)
                }
                return subscriptions
            }()
            
            publishingSubscription = Publishers.MergeMany(updateMediaQuerySubscriptions)
                .collect()
                .flatMap { attachments -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> in
                    let query = Mastodon.API.Statuses.PublishStatusQuery(
                        status: viewModel.composeStatusAttribute.composeContent.value,
                        mediaIDs: mediaIDs.isEmpty ? nil : mediaIDs,
                        pollOptions: pollOptions,
                        pollExpiresIn: pollExpiresIn
                    )
                    return viewModel.context.apiService.publishStatus(
                        domain: domain,
                        query: query,
                        mastodonAuthenticationBox: mastodonAuthenticationBox
                    )
                }
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: publish status %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: publish status success", ((#file as NSString).lastPathComponent), #line, #function)
                        stateMachine.enter(Finish.self)
                    }
                } receiveValue: { response in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: status %s published: %s", ((#file as NSString).lastPathComponent), #line, #function, response.value.id, response.value.uri)
                }
        }
    }
    
    class Fail: ComposeViewModel.PublishState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // allow discard publishing
            return stateClass == Publishing.self || stateClass == Finish.self
        }
    }
    
    class Finish: ComposeViewModel.PublishState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }

}
