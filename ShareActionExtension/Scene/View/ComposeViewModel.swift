//
//  ComposeViewModel.swift
//  ShareActionExtension
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import Foundation
import SwiftUI
import Combine

class ComposeViewModel: ObservableObject {

    var disposeBag = Set<AnyCancellable>()

    @Published var toolbarHeight: CGFloat = 0

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

        #if DEBUG
        avatarImageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")
        authorName = "Alice"
        authorUsername = "alice"
        #endif
    }

}

extension ComposeViewModel {
    func setupAttachmentViewModels(_ viewModels: [StatusAttachmentViewModel]) {
        attachmentViewModels = viewModels
        for viewModel in viewModels {
            viewModel.objectWillChange.sink { [weak self] _ in
                guard let self = self else { return }
                self.objectWillChange.send()
            }
            .store(in: &viewModel.disposeBag)
        }
    }

    func removeAttachmentViewModel(_ viewModel: StatusAttachmentViewModel) {
        if let index = attachmentViewModels.firstIndex(where: { $0 === viewModel }) {
            attachmentViewModels.remove(at: index)
        }
    }
}
