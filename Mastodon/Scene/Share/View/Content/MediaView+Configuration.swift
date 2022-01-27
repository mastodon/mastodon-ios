//
//  MediaView+Configuration.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-12.
//

import UIKit
import Combine
import CoreDataStack
import MastodonUI

extension MediaView {
    public static func configuration(status: Status) -> AnyPublisher<[MediaView.Configuration], Never> {
        func videoInfo(from attachment: MastodonAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assetURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.reblog ?? status
        return status.publisher(for: \.attachments)
            .map { attachments -> [MediaView.Configuration] in
                return attachments.map { attachment -> MediaView.Configuration in
                    switch attachment.kind {
                    case .image:
                        let info = MediaView.Configuration.ImageInfo(
                            aspectRadio: attachment.size,
                            assetURL: attachment.assetURL
                        )
                        return .image(info: info)
                    case .video:
                        let info = videoInfo(from: attachment)
                        return .video(info: info)
                    case .gifv:
                        let info = videoInfo(from: attachment)
                        return .gif(info: info)
                    case .audio:
                        // TODO:
                        let info = videoInfo(from: attachment)
                        return .video(info: info)
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
