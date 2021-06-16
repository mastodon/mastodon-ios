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
            // Display original on the iPad/Mac
            guard let previewURL = element.previewURL else { continue }
            let urlString = UIDevice.current.userInterfaceIdiom == .phone ? previewURL : element.url
            guard let meta = element.meta,
                  let width = meta.original?.width,
                  let height = meta.original?.height,
                  let url = URL(string: urlString) else {
                continue
            }
            let mosaicMeta = MosaicMeta(
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
