//
//  MosaicImageViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-23.
//

import UIKit
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
            metas.append(MosaicMeta(url: url, size: CGSize(width: width, height: height)))
        }
        self.metas = metas
    }
    
}

struct MosaicMeta {
    let url: URL
    let size: CGSize
}
