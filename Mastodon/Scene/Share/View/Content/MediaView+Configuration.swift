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
import AlamofireImage

extension MediaView {
    public static func configuration(status: Status) -> [MediaView.Configuration] {
        func videoInfo(from attachment: MastodonAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assetURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.reblog ?? status
        let attachments = status.attachments
        let configurations = attachments.map { attachment -> MediaView.Configuration in
            let configuration: MediaView.Configuration = {
                switch attachment.kind {
                case .image:
                    let info = MediaView.Configuration.ImageInfo(
                        aspectRadio: attachment.size,
                        assetURL: attachment.assetURL
                    )
                    return .init(
                        info: .image(info: info),
                        blurhash: attachment.blurhash
                    )
                case .video:
                    let info = videoInfo(from: attachment)
                    return .init(
                        info: .video(info: info),
                        blurhash: attachment.blurhash
                    )
                case .gifv:
                    let info = videoInfo(from: attachment)
                    return .init(
                        info: .gif(info: info),
                        blurhash: attachment.blurhash
                    )
                case .audio:
                    let info = videoInfo(from: attachment)
                    return .init(
                        info: .video(info: info),
                        blurhash: attachment.blurhash
                    )
                }   // end switch
            }()
            
            configuration.load()
            configuration.isReveal = status.isMediaSensitive ? status.isSensitiveToggled : true
            
            return configuration
        }
        
        return configurations
    }
}
