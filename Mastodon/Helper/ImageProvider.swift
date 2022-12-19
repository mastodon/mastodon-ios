//
//  ImageProvider.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-12-03.
//

import Foundation
import AlamofireImage
import UniformTypeIdentifiers
import UIKit

class ImageProvider: NSObject, NSItemProviderWriting {
    let url: URL
    let filter: ImageFilter?

    init(url: URL, filter: ImageFilter? = nil) {
        self.url = url
        self.filter = filter
    }

    var itemProvider: NSItemProvider {
        NSItemProvider(object: self)
    }

    static var writableTypeIdentifiersForItemProvider: [String] {
        [UTType.png.identifier]
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Progress? {
        let receipt = UIImageView.af.sharedImageDownloader.download(URLRequest(url: url), filter: filter, completion: { response in
            switch response.result {
            case .failure(let error): completionHandler(nil, error)
            case .success(let image): completionHandler(image.pngData(), nil)
            }
        })
        return receipt?.request.downloadProgress
    }
}
