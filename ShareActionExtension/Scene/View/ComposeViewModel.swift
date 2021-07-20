//
//  ComposeViewModel.swift
//  ShareActionExtension
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import Foundation
import SwiftUI
import Combine
import CoreDataStack

class ComposeViewModel: ObservableObject {

    var disposeBag = Set<AnyCancellable>()

    @Published var authentication: MastodonAuthentication?

    @Published var toolbarHeight: CGFloat = 0
    @Published var viewDidAppear = false

    @Published var avatarImageURL: URL?
    @Published var authorName: String = ""
    @Published var authorUsername: String = ""

    @Published var statusContent = ""
    @Published var statusPlaceholder = ""
    @Published var statusContentAttributedString = NSAttributedString()

    @Published var isContentWarningComposing = false
    @Published var contentWarningBackgroundColor = Color.secondary
    @Published var contentWarningPlaceholder = ""
    @Published var contentWarningContent = ""

    @Published private(set) var attachmentViewModels: [StatusAttachmentViewModel] = []

    @Published var characterCount = 0

    public init() {
        $statusContent
            .map { NSAttributedString(string: $0) }
            .assign(to: &$statusContentAttributedString)

        Publishers.CombineLatest3(
            $statusContent,
            $isContentWarningComposing,
            $contentWarningContent
        )
        .map { statusContent, isContentWarningComposing, contentWarningContent in
            var count = statusContent.count
            if isContentWarningComposing {
                count += contentWarningContent.count
            }
            return count
        }
        .assign(to: &$characterCount)

        // setup attribute updater
        $attachmentViewModels
            .receive(on: DispatchQueue.main)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { attachmentViewModels in
                // drive upload state
                // make image upload in the queue
                for attachmentViewModel in attachmentViewModels {
                    // skip when prefix N task when task finish OR fail OR uploading
                    guard let currentState = attachmentViewModel.uploadStateMachine.currentState else { break }
                    if currentState is StatusAttachmentViewModel.UploadState.Fail {
                        continue
                    }
                    if currentState is StatusAttachmentViewModel.UploadState.Finish {
                        continue
                    }
                    if currentState is StatusAttachmentViewModel.UploadState.Uploading {
                        break
                    }
                    // trigger uploading one by one
                    if currentState is StatusAttachmentViewModel.UploadState.Initial {
                        attachmentViewModel.uploadStateMachine.enter(StatusAttachmentViewModel.UploadState.Uploading.self)
                        break
                    }
                }
            }
            .store(in: &disposeBag)

        #if DEBUG
        // avatarImageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")
        // authorName = "Alice"
        // authorUsername = "alice"
        #endif
    }

}

extension ComposeViewModel {
    func setupAttachmentViewModels(_ viewModels: [StatusAttachmentViewModel]) {
        attachmentViewModels = viewModels
        for viewModel in viewModels {
            // set delegate
            viewModel.delegate = self
            // set observed
            viewModel.objectWillChange.sink { [weak self] _ in
                guard let self = self else { return }
                self.objectWillChange.send()
            }
            .store(in: &viewModel.disposeBag)
            // bind authentication
            $authentication
                .assign(to: \.value, on: viewModel.authentication)
                .store(in: &viewModel.disposeBag)
        }
    }

    func removeAttachmentViewModel(_ viewModel: StatusAttachmentViewModel) {
        if let index = attachmentViewModels.firstIndex(where: { $0 === viewModel }) {
            attachmentViewModels.remove(at: index)
        }
    }
}

// MARK: - StatusAttachmentViewModelDelegate
extension ComposeViewModel: StatusAttachmentViewModelDelegate {
    func statusAttachmentViewModel(_ viewModel: StatusAttachmentViewModel, uploadStateDidChange state: StatusAttachmentViewModel.UploadState?) {
        // trigger event update
        DispatchQueue.main.async {
            self.attachmentViewModels = self.attachmentViewModels
        }
    }
}
