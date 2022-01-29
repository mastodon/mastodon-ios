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
                            // TODO:
                            let info = videoInfo(from: attachment)
                            return .init(
                                info: .video(info: info),
                                blurhash: attachment.blurhash
                            )
                        }   // end switch
                    }()
                    
                    if let assetURL = configuration.assetURL,
                       let blurhash = configuration.blurhash
                    {
                        AppContext.shared.blurhashImageCacheService.image(
                            blurhash: blurhash,
                            size: configuration.aspectRadio,
                            url: assetURL
                        )
                        .assign(to: \.blurhashImage, on: configuration)
                        .store(in: &configuration.blurhashImageDisposeBag)
                    }
                    
                    configuration.isReveal = status.sensitive ? status.isMediaSensitiveToggled : true
                    
                    return configuration
                }
            }
            .eraseToAnyPublisher()
    }
}
