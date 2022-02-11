//
//  StatusAttachmentViewModel+UploadState.swift
//  ShareActionExtension
//
//  Created by MainasuK Cirno on 2021-7-20.
//

import os.log
import Foundation
import Combine
import GameplayKit
import MastodonSDK

extension StatusAttachmentViewModel {
    class UploadState: GKState {
        weak var viewModel: StatusAttachmentViewModel?

        init(viewModel: StatusAttachmentViewModel) {
            self.viewModel = viewModel
        }

        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.uploadStateMachineSubject.send(self)
        }
    }
}

extension StatusAttachmentViewModel.UploadState {

    class Initial: StatusAttachmentViewModel.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard viewModel?.authentication.value != nil else { return false }
            if stateClass == Initial.self {
                return true
            }

            if viewModel?.file.value != nil {
                return stateClass == Uploading.self
            } else {
                return stateClass == Fail.self
            }
        }
    }

    class Uploading: StatusAttachmentViewModel.UploadState {
        let logger = Logger(subsystem: "StatusAttachmentViewModel.UploadState.Uploading", category: "logic")
        var needsFallback = false

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Finish.self || stateClass == Uploading.self
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authentication = viewModel.authentication.value else { return }
            guard let file = viewModel.file.value else { return }

            let description = viewModel.descriptionContent
            let query = Mastodon.API.Media.UploadMediaQuery(
                file: file,
                thumbnail: nil,
                description: description,
                focus: nil
            )

            let mastodonAuthenticationBox = MastodonAuthenticationBox(
                authenticationRecord: .init(objectID: authentication.objectID),
                domain: authentication.domain,
                userID: authentication.userID,
                appAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.appAccessToken),
                userAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
            )

            // and needs clone the `query` if needs retry
            APIService.shared.uploadMedia(
                domain: mastodonAuthenticationBox.domain,
                query: query,
                mastodonAuthenticationBox: mastodonAuthenticationBox,
                needsFallback: needsFallback
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    if let apiError = error as? Mastodon.API.Error,
                       apiError.httpResponseStatus == .notFound,
                       self.needsFallback == false
                    {
                        self.needsFallback = true
                        stateMachine.enter(Uploading.self)
                        self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fallback to V1")
                    } else {
                        self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fail: \(error.localizedDescription)")
                        viewModel.error = error
                        stateMachine.enter(Fail.self)
                    }
                case .finished:
                    self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): upload attachment success")
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): upload attachment \(response.value.id) success, \(response.value.url ?? "<nil>")")
                viewModel.attachment.value = response.value
                stateMachine.enter(Finish.self)
            }
            .store(in: &viewModel.disposeBag)
        }

    }

    class Fail: StatusAttachmentViewModel.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // allow discard publishing
            return stateClass == Uploading.self || stateClass == Finish.self
        }
    }

    class Finish: StatusAttachmentViewModel.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }

}

