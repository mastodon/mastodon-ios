//
//  NSItemProvider.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import os.log
import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import PhotosUI

// load image with low memory usage
// Refs: https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/

extension NSItemProvider {
    
    static let logger = Logger(subsystem: "NSItemProvider", category: "Logic")
    
    public struct ImageLoadResult {
        public let data: Data
        public let type: UTType?
        
        public  init(data: Data, type: UTType?) {
            self.data = data
            self.type = type
        }
    }

    public func loadImageData() async throws -> ImageLoadResult? {
        #if APP_EXTENSION
        let maxPixelSize = 4096        // not limit but may upload fail
        #else
        let maxPixelSize = 1536        // fit 120MB RAM limit
        #endif

        let result = try await self.loadItem(forTypeIdentifier: UTType.image.identifier, options: [NSItemProviderPreferredImageSizeKey: CGSize(width: maxPixelSize, height: maxPixelSize)])
        if let image = result as? UIImage {
            let isPNG = (image.cgImage?.utType as String?) == UTType.png.identifier
            guard let data = isPNG ? image.pngData() : image.jpegData(compressionQuality: 0.75) else {
                return nil
            }
            
            NSItemProvider.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): load image \(data.count.formatted(.byteCount(style: .memory)), privacy: .public)")
            return ImageLoadResult(
                data: data,
                type: isPNG ? .png : .jpeg
            )
        } else if let url = result as? URL {
            guard
                let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary)
            else {
                assertionFailure()
                return nil
            }
            
            guard
                let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                ] as CFDictionary)
            else { return nil }
            let isPNG = (cgImage.utType as String?) == UTType.png.identifier

            let data = NSMutableData()
            guard let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
                return nil
            }
            
            CGImageDestinationAddImage(imageDestination, cgImage, [
                kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75
            ] as CFDictionary)
            CGImageDestinationFinalize(imageDestination)

            NSItemProvider.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): load image \(data.length.formatted(.byteCount(style: .memory)))")
            
            return ImageLoadResult(
                data: data as Data,
                type: cgImage.utType.flatMap { UTType($0 as String) }
            )
        } else {
            assertionFailure("Invalid image type \(type(of: result))")
            return nil
        }
    }
}

extension NSItemProvider {
    
    public struct VideoLoadResult {
        public let url: URL
        public let sizeInBytes: UInt64
    }
    
    public func loadVideoData() async throws -> VideoLoadResult? {
        try await withCheckedThrowingContinuation { continuation in
            loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                    return
                }
                
                guard let url = url,
                      let attribute = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let sizeInBytes = attribute[.size] as? UInt64
                else {
                    continuation.resume(with: .success(nil))
                    assertionFailure()
                    return
                }
                
                do {
                    let fileURL = try FileManager.default.createTemporaryFileURL(
                        filename: UUID().uuidString,
                        pathExtension: url.pathExtension
                    )
                    try FileManager.default.copyItem(at: url, to: fileURL)
                    let result = VideoLoadResult(
                        url: fileURL,
                        sizeInBytes: sizeInBytes
                    )
                    
                    continuation.resume(with: .success(result))
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }   // end loadFileRepresentation
        }   // end try await withCheckedThrowingContinuation
    }   // end func
    
}
