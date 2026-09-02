//
//  MediaView+Configuration.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData // needed for MastodonAttachment
import CoreDataStack // needed for MastodonAttachment
import Photos
import AlamofireImage
import MastodonCore
import MastodonSDK

extension MediaView {
    public class Configuration: Hashable {
        
        public let info: Info
        public let blurhash: String?
        public let index: Int
        public let total: Int
        
        public var isReveal = true
        @Published public var previewImage: UIImage?
        @Published public var blurhashImage: UIImage?
        public var blurhashImageDisposeBag = Set<AnyCancellable>()
        
        public init(
            info: MediaView.Configuration.Info,
            blurhash: String?,
            index: Int,
            total: Int
        ) {
            self.info = info
            self.blurhash = blurhash
            self.index = index
            self.total = total
        }
        
        public var aspectRadio: CGSize {
            switch info {
            case .image(let info):      return info.aspectRadio
            case .gif(let info):        return info.aspectRadio
            case .video(let info):      return info.aspectRadio
            }
        }
        
        public var previewURL: String? {
            switch info {
            case .image(let info):
                return info.assetURL
            case .gif(let info):
                return info.previewURL
            case .video(let info):
                return info.previewURL
            }
        }
        
        public var assetURL: String? {
            switch info {
            case .image(let info):
                return info.assetURL
            case .gif(let info):
                return info.assetURL
            case .video(let info):
                return info.assetURL
            }
        }
        
        public var resourceType: PHAssetResourceType {
            switch info {
            case .image:
                return .photo
            case .gif:
                return .video
            case .video:
                return .video
            }
        }
        
        public static func == (lhs: MediaView.Configuration, rhs: MediaView.Configuration) -> Bool {
            return lhs.info == rhs.info
                && lhs.blurhash == rhs.blurhash
                && lhs.isReveal == rhs.isReveal
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(info)
            hasher.combine(blurhash)
        }
        
    }
}

extension MediaView.Configuration {
    
    public enum Info: Hashable {
        case image(info: ImageInfo)
        case gif(info: VideoInfo)
        case video(info: VideoInfo)
    }
    
    public struct ImageInfo: Hashable {
        public let aspectRadio: CGSize
        public let assetURL: String?
        public let altDescription: String?
        public let focus: CGPoint?
        
        public init(
            aspectRadio: CGSize,
            assetURL: String?,
            altDescription: String?,
            focus: CGPoint?
        ) {
            self.aspectRadio = aspectRadio
            self.assetURL = assetURL
            self.altDescription = altDescription
            self.focus = focus
        }
    }
    
    public struct VideoInfo: Hashable {
        public let aspectRadio: CGSize
        public let assetURL: String?
        public let previewURL: String?
        public let altDescription: String?
        public let durationMS: Int?
        
        public init(
            aspectRadio: CGSize,
            assetURL: String?,
            previewURL: String?,
            altDescription: String?,
            durationMS: Int?
        ) {
            self.aspectRadio = aspectRadio
            self.assetURL = assetURL
            self.previewURL = previewURL
            self.durationMS = durationMS
            self.altDescription = altDescription
        }
    }
    
}

extension MediaView.Configuration {
    
    public func load() {
        if let previewURL = previewURL,
           let url = URL(string: previewURL)
        {
            let placeholder = UIImage.placeholder(color: .systemGray6)
            let request = URLRequest(url: url)
            ImageDownloader.default.download(request, completion:  { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                case .success(let image):
                    self.previewImage = image
                case .failure:
                    self.previewImage = placeholder
                }
            })
        }
        
        if let assetURL = assetURL,
           let blurhash = blurhash
        {
            BlurhashImageCacheService.shared.image(
                blurhash: blurhash,
                size: aspectRadio,
                url: assetURL
            )
            .assign(to: \.blurhashImage, on: self)
            .store(in: &blurhashImageDisposeBag)
        }
    }
    
}
