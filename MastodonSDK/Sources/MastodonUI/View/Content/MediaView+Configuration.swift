//
//  MediaView+Configuration.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData
import Photos
import AlamofireImage
import MastodonCore

extension MediaView {
    public class Configuration: Hashable {
        
        var disposeBag = Set<AnyCancellable>()
        
        public let info: Info
        public let blurhash: String?
        
        @Published public var isReveal = true
        @Published public var previewImage: UIImage?
        @Published public var blurhashImage: UIImage?
        public var blurhashImageDisposeBag = Set<AnyCancellable>()
        
        public init(
            info: MediaView.Configuration.Info,
            blurhash: String?
        ) {
            self.info = info
            self.blurhash = blurhash
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
        
        public init(
            aspectRadio: CGSize,
            assetURL: String?
        ) {
            self.aspectRadio = aspectRadio
            self.assetURL = assetURL
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(aspectRadio.width)
            hasher.combine(aspectRadio.height)
            assetURL.flatMap { hasher.combine($0) }
        }
    }
    
    public struct VideoInfo: Hashable {
        public let aspectRadio: CGSize
        public let assetURL: String?
        public let previewURL: String?
        public let durationMS: Int?
        
        public init(
            aspectRadio: CGSize,
            assetURL: String?,
            previewURL: String?,
            durationMS: Int?
        ) {
            self.aspectRadio = aspectRadio
            self.assetURL = assetURL
            self.previewURL = previewURL
            self.durationMS = durationMS
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(aspectRadio.width)
            hasher.combine(aspectRadio.height)
            assetURL.flatMap { hasher.combine($0) }
            previewURL.flatMap { hasher.combine($0) }
            durationMS.flatMap { hasher.combine($0) }
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
