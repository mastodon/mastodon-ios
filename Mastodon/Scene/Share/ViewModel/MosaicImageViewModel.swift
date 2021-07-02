//
//  MosaicImageViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-23.
//

import UIKit
import Combine
import CoreDataStack

struct MosaicImageViewModel {
    
    let metas: [MosaicMeta]
    
    init(mediaAttachments: [Attachment]) {
        var metas: [MosaicMeta] = []
        for element in mediaAttachments where element.type == .image {
            guard let meta = element.meta,
                  let width = meta.original?.width,
                  let height = meta.original?.height,
                  let url = URL(string: element.url) else {
                continue
            }
            let mosaicMeta = MosaicMeta(
                previewURL: element.previewURL.flatMap { URL(string: $0) },
                url: url,
                size: CGSize(width: width, height: height),
                blurhash: element.blurhash,
                altText: element.descriptionString
            )
            metas.append(mosaicMeta)
        }
        self.metas = metas
    }
    
}

struct MosaicMeta {
    static let edgeMaxLength: CGFloat = 20

    let previewURL: URL?
    let url: URL
    let size: CGSize
    let blurhash: String?
    let altText: String?

    func blurhashImagePublisher() -> AnyPublisher<UIImage?, Never> {
        guard let blurhash = blurhash else {
            return Just(nil).eraseToAnyPublisher()
        }
        return AppContext.shared.blurhashImageCacheService.image(blurhash: blurhash, size: size, url: url)
    }
    
}
