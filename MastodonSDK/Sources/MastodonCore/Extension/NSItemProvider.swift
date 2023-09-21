//
//  NSItemProvider.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import PhotosUI

// load image with low memory usage
// Refs: https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/

extension NSItemProvider {
    
    public struct ImageLoadResult {
        public let data: Data
        public let type: UTType?
        
        public  init(data: Data, type: UTType?) {
            self.data = data
            self.type = type
        }
    }

    public func loadImageData() async throws -> ImageLoadResult? {
        try await withCheckedThrowingContinuation { continuation in
            loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                    return
                }
                
                guard let url = url else {
                    continuation.resume(with: .success(nil))
                    assertionFailure()
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
                
                let downsampleOptions = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                ] as CFDictionary
                
                guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
                    continuation.resume(with: .success(nil))
                    return
                }
                
                let data = NSMutableData()
                guard let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
                    continuation.resume(with: .success(nil))
                    assertionFailure()
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
                
                let result = ImageLoadResult(
                    data: data as Data,
                    type: cgImage.utType.flatMap { UTType($0 as String) }
                )

                continuation.resume(with: .success(result))
            }
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
