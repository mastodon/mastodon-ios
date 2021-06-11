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
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.MosaicMeta.working-queue", qos: .userInitiated, attributes: .concurrent)

    func blurhashImagePublisher() -> AnyPublisher<UIImage?, Never> {
        return Future { promise in
            workingQueue.async {
                let image = self.blurhashImage()
                promise(.success(image))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func blurhashImage() -> UIImage? {
        guard let blurhash = blurhash else {
            return nil
        }
        
        let imageSize: CGSize = {
            let aspectRadio = size.width / size.height
            if size.width > size.height {
                let width: CGFloat = MosaicMeta.edgeMaxLength
                let height = width / aspectRadio
                return CGSize(width: width, height: height)
            } else {
                let height: CGFloat = MosaicMeta.edgeMaxLength
                let width = height * aspectRadio
                return CGSize(width: width, height: height)
            }
        }()
        
        let image = UIImage(blurHash: blurhash, size: imageSize)

        return image
    }
    
}
