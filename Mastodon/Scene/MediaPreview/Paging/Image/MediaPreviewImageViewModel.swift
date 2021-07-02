//
//  MediaPreviewImageViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import os.log
import UIKit
import Combine
import Nuke

class MediaPreviewImageViewModel {

    var disposeBag = Set<AnyCancellable>()
    
    // input
    let item: ImagePreviewItem
    
    // output
    let image: CurrentValueSubject<UIImage?, Never>
    let altText: String?
        
    init(meta: RemoteImagePreviewMeta) {
        self.item = .status(meta)
        self.image = CurrentValueSubject(meta.thumbnail)
        self.altText = meta.altText
        
        let url = meta.url

        ImagePipeline.shared.imagePublisher(with: url)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription, error.localizedDescription)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s success", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.image.value = response.image
            }
            .store(in: &disposeBag)
    }
    
    init(meta: LocalImagePreviewMeta) {
        self.item = .local(meta)
        self.image = CurrentValueSubject(meta.image)
        self.altText = nil
    }
    
}

extension MediaPreviewImageViewModel {
    enum ImagePreviewItem {
        case status(RemoteImagePreviewMeta)
        case local(LocalImagePreviewMeta)
        
        var activityItems: [Any] {
            var items: [Any] = []
            
            switch self {
            case .status(let meta):
                items.append(meta.url)
            case .local(let meta):
                items.append(meta.image)
            }
            
            return items
        }
    }
    
    struct RemoteImagePreviewMeta {
        let url: URL
        let thumbnail: UIImage?
        let altText: String?
    }
    
    struct LocalImagePreviewMeta {
        let image: UIImage
    }
    
}
