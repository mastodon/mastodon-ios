//
//  MastodonAttachmentService+UploadState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import os.log
import Foundation
import Combine
import GameplayKit
import MastodonSDK

extension MastodonAttachmentService {
    class UploadState: GKState {
        weak var service: MastodonAttachmentService?
        
        init(service: MastodonAttachmentService) {
            self.service = service
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            service?.uploadStateMachineSubject.send(self)
        }
    }
}

extension MastodonAttachmentService.UploadState {
    
    class Initial: MastodonAttachmentService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard service?.authenticationBox != nil else { return false }
            if stateClass == Initial.self {
                return true
            }

            if service?.file.value != nil {
                return stateClass == Uploading.self
            } else {
                return stateClass == Fail.self
            }
        }
    }
    
    class Uploading: MastodonAttachmentService.UploadState {
        var needsFallback = false

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Finish.self || stateClass == Uploading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let service = service, let stateMachine = stateMachine else { return }
            guard let authenticationBox = service.authenticationBox else { return }
            guard let file = service.file.value else { return }
            
            let description = service.description.value
            let query = Mastodon.API.Media.UploadMediaQuery(
                file: file,
                thumbnail: nil,
                description: description,
                focus: nil
            )

            // and needs clone the `query` if needs retry
            service.context.apiService.uploadMedia(
                domain: authenticationBox.domain,
                query: query,
                mastodonAuthenticationBox: authenticationBox,
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
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: upload attachment fallback to V1", ((#file as NSString).lastPathComponent), #line, #function)
                    } else {
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: upload attachment fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        service.error.send(error)
                        stateMachine.enter(Fail.self)
                    }
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: upload attachment success", ((#file as NSString).lastPathComponent), #line, #function)
                    break
                }
            } receiveValue: { response in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: upload attachment %s success: %s", ((#file as NSString).lastPathComponent), #line, #function, response.value.id, response.value.url ?? "<nil>")
                service.attachment.value = response.value
                stateMachine.enter(Finish.self)
            }
            .store(in: &service.disposeBag)
        }

    }
    
    class Fail: MastodonAttachmentService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // allow discard publishing
            return stateClass == Uploading.self || stateClass == Finish.self
        }
    }
    
    class Finish: MastodonAttachmentService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
}

