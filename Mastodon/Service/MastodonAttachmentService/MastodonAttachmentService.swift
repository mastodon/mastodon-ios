//
//  MastodonAttachmentService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit
import Combine
import PhotosUI
import Kingfisher
import GameplayKit
import MastodonSDK

protocol MastodonAttachmentServiceDelegate: class {
    func mastodonAttachmentService(_ service: MastodonAttachmentService, uploadStateDidChange state: MastodonAttachmentService.UploadState?)
}

final class MastodonAttachmentService {
    
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: MastodonAttachmentServiceDelegate?
    
    let identifier = UUID()
    
    // input
    let context: AppContext
    let pickerResult: PHPickerResult
    var authenticationBox: AuthenticationService.MastodonAuthenticationBox?
    
    // output
    // TODO: handle video/GIF/Audio data
    let imageData = CurrentValueSubject<Data?, Never>(nil)
    let attachment = CurrentValueSubject<Mastodon.Entity.Attachment?, Never>(nil)
    let description = CurrentValueSubject<String?, Never>(nil)
    let error = CurrentValueSubject<Error?, Never>(nil)
    
    private(set) lazy var uploadStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            UploadState.Initial(service: self),
            UploadState.Uploading(service: self),
            UploadState.Fail(service: self),
            UploadState.Finish(service: self),
        ])
        stateMachine.enter(UploadState.Initial.self)
        return stateMachine
    }()
    lazy var uploadStateMachineSubject = CurrentValueSubject<MastodonAttachmentService.UploadState?, Never>(nil)

    init(
        context: AppContext,
        pickerResult: PHPickerResult,
        initalAuthenticationBox: AuthenticationService.MastodonAuthenticationBox?
    ) {
        self.context = context
        self.pickerResult = pickerResult
        self.authenticationBox = initalAuthenticationBox
        // end init
        
        uploadStateMachineSubject
            .sink { [weak self] state in
                guard let self = self else { return }
                self.delegate?.mastodonAttachmentService(self, uploadStateDidChange: state)
            }
            .store(in: &disposeBag)
        
        PHPickerResultLoader.loadImageData(from: pickerResult)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.error.value = error
                case .finished:
                    break
                }
            } receiveValue: { [weak self] imageData in
                guard let self = self else { return }
                self.imageData.value = imageData
                
                // Try pre-upload attachment for current active user
                self.uploadStateMachine.enter(UploadState.Uploading.self)
            }
            .store(in: &disposeBag)
    }
    
}

extension MastodonAttachmentService {
    // FIXME: needs reset state for multiple account posting support
    func uploading(mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox) -> Bool {
        authenticationBox = mastodonAuthenticationBox
        return uploadStateMachine.enter(UploadState.self)
    }
}

extension MastodonAttachmentService: Equatable, Hashable {
    
    static func == (lhs: MastodonAttachmentService, rhs: MastodonAttachmentService) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
}
