//
//  UserView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-1-19.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import MastodonCore

extension UserView {
    public final class ViewModel: ObservableObject {
        public var disposeBag = Set<AnyCancellable>()
        public var observations = Set<NSKeyValueObservation>()
        
        let logger = Logger(subsystem: "StatusView", category: "ViewModel")
        
        @Published public var authorAvatarImage: UIImage?
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?
    }
}

extension UserView.ViewModel {
    func bind(userView: UserView) {
        // avatar
        Publishers.CombineLatest(
            $authorAvatarImage,
            $authorAvatarImageURL
        )
        .sink { image, url in
            let configuration: AvatarImageView.Configuration = {
                if let image = image {
                    return AvatarImageView.Configuration(image: image)
                } else {
                    return AvatarImageView.Configuration(url: url)
                }
            }()
            userView.avatarButton.avatarImageView.configure(configuration: configuration)
            userView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 7)))
        }
        .store(in: &disposeBag)
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                userView.authorNameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // username
        $authorUsername
            .map { text -> String in
                guard let text = text else { return "" }
                return "@\(text)"
            }
            .sink { username in
                let metaContent = PlaintextMetaContent(string: username)
                userView.authorUsernameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
    }
}
