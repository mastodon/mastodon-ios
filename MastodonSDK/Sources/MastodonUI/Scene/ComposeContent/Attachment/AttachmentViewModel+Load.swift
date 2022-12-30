//
//  AttachmentViewModel+Load.swift
//  
//
//  Created by MainasuK on 2022/11/8.
//

import os.log
import UIKit
import AVKit
import UniformTypeIdentifiers

extension AttachmentViewModel {
    
    @MainActor
    func load(input: Input) async throws -> Output {
        switch input {
        case .image(let image):
            guard let data = image.normalized()?.pngData() else {
                throw AttachmentError.invalidAttachmentType
            }
            return .image(data, imageKind: .png)
        case .url(let url):
            do {
                let output = try await AttachmentViewModel.load(url: url)
                return output
            } catch {
                throw error
            }
        case .pickerResult(let pickerResult):
            do {
                let output = try await AttachmentViewModel.load(itemProvider: pickerResult.itemProvider)
                return output
            } catch {
                throw error
            }
        case .itemProvider(let itemProvider):
            do {
                let output = try await AttachmentViewModel.load(itemProvider: itemProvider)
                return output
            } catch {
                throw error
            }
        }
    }
    
    private static func load(url: URL) async throws -> Output {
        guard let uti = UTType(filenameExtension: url.pathExtension) else {
            throw AttachmentError.invalidAttachmentType
        }
        
        if uti.conforms(to: .image) {
            guard url.startAccessingSecurityScopedResource() else {
                throw AttachmentError.invalidAttachmentType
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let imageData = try Data(contentsOf: url)
            return .image(imageData, imageKind: imageData.kf.imageFormat == .PNG ? .png : .jpg)
        } else if uti.conforms(to: .movie) {
            guard url.startAccessingSecurityScopedResource() else {
                throw AttachmentError.invalidAttachmentType
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let fileName = UUID().uuidString
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let fileURL = tempDirectoryURL.appendingPathComponent(fileName).appendingPathExtension(url.pathExtension)
            try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.copyItem(at: url, to: fileURL)
            return .video(fileURL, mimeType: UTType.movie.preferredMIMEType ?? "video/mp4")
        } else {
            throw AttachmentError.invalidAttachmentType
        }
    }
    
    private static func load(itemProvider: NSItemProvider) async throws -> Output {
        if itemProvider.isImage() {
            guard let result = try await itemProvider.loadImageData() else {
                throw AttachmentError.invalidAttachmentType
            }
            let imageKind: Output.ImageKind = {
                if let type = result.type {
                    if type == UTType.png {
                        return .png
                    }
                    if type == UTType.jpeg {
                        return .jpg
                    }
                }
                
                let imageData = result.data

                if imageData.kf.imageFormat == .PNG {
                    return .png
                }
                if imageData.kf.imageFormat == .JPEG {
                    return .jpg
                }
                
                assertionFailure("unknown image kind")
                return .jpg
            }()
            return .image(result.data, imageKind: imageKind)
        } else if itemProvider.isMovie() {
            guard let result = try await itemProvider.loadVideoData() else {
                throw AttachmentError.invalidAttachmentType
            }
            return .video(result.url, mimeType: "video/mp4")
        } else {
            assertionFailure()
            throw AttachmentError.invalidAttachmentType
        }
    }

}

extension AttachmentViewModel {
    static func createThumbnailForVideo(url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let asset = AVURLAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true   // fix orientation
        do {
            let cgImage = try assetImageGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            return image
        } catch {
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): thumbnail generate fail: \(error.localizedDescription)")
            return nil
        }
    }
}

extension NSItemProvider {
    func isImage() -> Bool {
        return hasRepresentationConforming(
            toTypeIdentifier: UTType.image.identifier,
            fileOptions: []
        )
    }
    
    func isMovie() -> Bool {
        return hasRepresentationConforming(
            toTypeIdentifier: UTType.movie.identifier,
            fileOptions: []
        )
    }
}
