//
//  ComposeViewModel.swift
//  ShareActionExtension
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import Foundation
import SwiftUI
import Combine

public class ComposeViewModel: ObservableObject {

    var disposeBag = Set<AnyCancellable>()

    @Published var frame: CGRect = .zero

    @Published var avatarImageURL: URL?
    @Published var authorName: String = ""
    @Published var authorUsername: String = ""

    @Published var statusContent = ""
    @Published var statusContentAttributedString = NSAttributedString()
    @Published var contentWarningContent = ""

    @Published var attachments: [UIImage] = []

    public init() {
        $statusContent
            .map { NSAttributedString(string: $0) }
            .assign(to: &$statusContentAttributedString)

        #if DEBUG
        avatarImageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")
        authorName = "Alice"
        authorUsername = "alice"
        attachments = [
            UIImage(systemName: "photo")!,
            UIImage(systemName: "photo")!,
            UIImage(systemName: "photo")!,
            UIImage(systemName: "photo")!,
        ]
        #endif
    }

}
