//
//  ItemProviderLoader.swift
//  MastodonCore
//
//  Created by MainasuK Cirno on 2021-3-18.
//

import Foundation
import Combine
import MobileCoreServices
import PhotosUI
import MastodonSDK

// load image with low memory usage
// Refs: https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/
public enum ItemProviderLoader {
    public static func loadImageData(from result: PHPickerResult) -> Future<Mastodon.Query.MediaAttachment?, Error> {
        loadImageData(from: result.itemProvider)
    }
    
    public static func loadImageData(from itemProvider: NSItemProvider) -> Future<Mastodon.Query.MediaAttachment?, Error> {
        Future { promise in
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard  let url = url else {
                    promise(.success(nil))
                    return
                }
                
                let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
                    return
                }

                #if APP_EXTENSION
                let maxPixelSize: Int = 4096        // not limit but may upload fail
                #else
                let maxPixelSize: Int = 1536        // fit 120MB RAM limit
                #endif
                
                let downsampleOptions: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                ]
                
                guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
                    // fallback to loadItem when create thumbnail failure
                    itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { image, error in
                        if let error = error {
                            promise(.failure(error))
                        }
                        
                        guard let image = image as? UIImage,
                              let data = image.jpegData(compressionQuality: 0.75)
                        else {
                            promise(.success(nil))
                            assertionFailure()
                            return
                        }
                        
                        let file = Mastodon.Query.MediaAttachment.jpeg(data)
                        promise(.success(file))
                        
                    }   // end itemProvider.loadItem
                    return
                }
                
                let data = NSMutableData()
                guard let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
                    promise(.success(nil))
                    return
                }
                
                let isPNG: Bool = {
                    guard let utType = cgImage.utType else { return false }
                    return (utType as String) == UTType.png.identifier
                }()
                
                let destinationProperties = [
                    kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75
                ] as CFDictionary
                
                CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
                CGImageDestinationFinalize(imageDestination)
                
                let file = Mastodon.Query.MediaAttachment.jpeg(data as Data)
                promise(.success(file))
            }
        }
    }

}

extension ItemProviderLoader {

    public static func loadVideoData(from result: PHPickerResult) -> Future<Mastodon.Query.MediaAttachment?, Error> {
        loadVideoData(from: result.itemProvider)
    }

    public static func loadVideoData(from itemProvider: NSItemProvider) -> Future<Mastodon.Query.MediaAttachment?, Error> {
        Future { promise in
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let url = url else {
                    promise(.success(nil))
                    return
                }
                
                let fileName = UUID().uuidString
                let tempDirectoryURL = FileManager.default.temporaryDirectory
                let fileURL = tempDirectoryURL.appendingPathComponent(fileName).appendingPathExtension(url.pathExtension)
                do {
                    try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    try FileManager.default.copyItem(at: url, to: fileURL)
                    let file = Mastodon.Query.MediaAttachment.other(fileURL, fileExtension: fileURL.pathExtension, mimeType: UTType.movie.preferredMIMEType ?? "video/mp4")
                    promise(.success(file))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
}
