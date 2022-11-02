//
//  AttachmentViewModel+Upload.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import os.log
import UIKit
import Kingfisher
import UniformTypeIdentifiers
import MastodonCore
import MastodonSDK

// objc.io
// ref: https://talk.objc.io/episodes/S01E269-swift-concurrency-async-sequences-part-1
struct Chunked<Base: AsyncSequence>: AsyncSequence where Base.Element == UInt8 {
    var base: Base
    var chunkSize: Int = 1 * 1024 * 1024      // 1 MiB
    typealias Element = Data
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        var chunkSize: Int
        
        mutating func next() async throws -> Data? {
            var result = Data()
            while let element = try await base.next() {
                result.append(element)
                if result.count == chunkSize { return result }
            }
            return result.isEmpty ? nil : result
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), chunkSize: chunkSize)
    }
}

extension AsyncSequence where Element == UInt8 {
    var chunked: Chunked<Self> {
        Chunked(base: self)
    }
}

extension Data {
    fileprivate func chunks(size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            Data(self[$0..<Swift.min(count, $0 + size)])
        }
    }
}

// Twitter Only
//extension AttachmentViewModel {
//    class SliceResult {
//
//        let fileURL: URL
//        let chunks: Chunked<FileHandle.AsyncBytes>
//        let chunkCount: Int
//        let type: UTType
//        let sizeInBytes: UInt64
//
//        public init?(
//            url: URL,
//            type: UTType
//        ) {
//            guard let chunks = try? FileHandle(forReadingFrom: url).bytes.chunked else { return nil }
//            let _sizeInBytes: UInt64? = {
//                let attribute = try? FileManager.default.attributesOfItem(atPath: url.path)
//                return attribute?[.size] as? UInt64
//            }()
//            guard let sizeInBytes = _sizeInBytes else { return nil }
//
//            self.fileURL = url
//            self.chunks = chunks
//            self.chunkCount = SliceResult.chunkCount(chunkSize: UInt64(chunks.chunkSize), sizeInBytes: sizeInBytes)
//            self.type = type
//            self.sizeInBytes = sizeInBytes
//        }
//
//        public init?(
//            imageData: Data,
//            type: UTType
//        ) {
//            let _fileURL = try? FileManager.default.createTemporaryFileURL(
//                filename: UUID().uuidString,
//                pathExtension: imageData.kf.imageFormat == .PNG ? "png" : "jpeg"
//            )
//            guard let fileURL = _fileURL else { return nil }
//
//            do {
//                try imageData.write(to: fileURL)
//            } catch {
//                return nil
//            }
//
//            guard let chunks = try? FileHandle(forReadingFrom: fileURL).bytes.chunked else {
//                return nil
//            }
//            let sizeInBytes = UInt64(imageData.count)
//
//            self.fileURL = fileURL
//            self.chunks = chunks
//            self.chunkCount = SliceResult.chunkCount(chunkSize: UInt64(chunks.chunkSize), sizeInBytes: sizeInBytes)
//            self.type = type
//            self.sizeInBytes = sizeInBytes
//        }
//
//        static func chunkCount(chunkSize: UInt64, sizeInBytes: UInt64) -> Int {
//            guard sizeInBytes > 0 else { return 0 }
//            let count = sizeInBytes / chunkSize
//            let remains = sizeInBytes % chunkSize
//            let result = remains > 0 ? count + 1 : count
//            return Int(result)
//        }
//
//    }
//
//    static func slice(output: Output, sizeLimit: SizeLimit) -> SliceResult? {
//        // needs execute in background
//        assert(!Thread.isMainThread)
//
//        // try png then use JPEG compress with Q=0.8
//        // then slice into 1MiB chunks
//        switch output {
//        case .image(let data, _):
//            let maxPayloadSizeInBytes = sizeLimit.image
//
//            // use processed imageData to remove EXIF
//            guard let image = UIImage(data: data),
//                  var imageData = image.pngData()
//            else { return nil }
//
//            var didRemoveEXIF = false
//            repeat {
//                guard let image = KFCrossPlatformImage(data: imageData) else { return nil }
//                if imageData.kf.imageFormat == .PNG {
//                    // A. png image
//                    guard let pngData = image.pngData() else { return nil }
//                    didRemoveEXIF = true
//                    if pngData.count > maxPayloadSizeInBytes {
//                        guard let compressedJpegData = image.jpegData(compressionQuality: 0.8) else { return nil }
//                        os_log("%{public}s[%{public}ld], %{public}s: compress png %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
//                        imageData = compressedJpegData
//                    } else {
//                        os_log("%{public}s[%{public}ld], %{public}s: png %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(pngData.count) / 1024 / 1024)
//                        imageData = pngData
//                    }
//                } else {
//                    // B. other image
//                    if !didRemoveEXIF {
//                        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return nil }
//                        os_log("%{public}s[%{public}ld], %{public}s: compress jpeg %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(jpegData.count) / 1024 / 1024)
//                        imageData = jpegData
//                        didRemoveEXIF = true
//                    } else {
//                        let targetSize = CGSize(width: image.size.width * 0.8, height: image.size.height * 0.8)
//                        let scaledImage = image.af.imageScaled(to: targetSize)
//                        guard let compressedJpegData = scaledImage.jpegData(compressionQuality: 0.8) else { return nil }
//                        os_log("%{public}s[%{public}ld], %{public}s: compress jpeg %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
//                        imageData = compressedJpegData
//                    }
//                }
//            } while (imageData.count > maxPayloadSizeInBytes)
//
//            return SliceResult(
//                imageData: imageData,
//                type: imageData.kf.imageFormat == .PNG ? UTType.png : UTType.jpeg
//            )
//
////        case .gif(let url):
////            fatalError()
//        case .video(let url, _):
//            return SliceResult(
//                url: url,
//                type: .movie
//            )
//        }
//    }
//}

extension AttachmentViewModel {
    struct UploadContext {
        let apiService: APIService
        let authContext: AuthContext
    }
    
    enum UploadResult {
        case mastodon(Mastodon.Response.Content<Mastodon.Entity.Attachment>)
    }
}

extension AttachmentViewModel {
    func upload(context: UploadContext) async throws -> UploadResult  {
        return try await uploadMastodonMedia(
            context: context
        )
    }
    
    private func uploadMastodonMedia(
        context: UploadContext
    ) async throws -> UploadResult {
        guard let output = self.output else {
            throw AppError.badRequest
        }
        
        let attachment = output.asAttachment
        
        let query = Mastodon.API.Media.UploadMediaQuery(
            file: attachment,
            thumbnail: nil,
            description: {
                let caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                return caption.isEmpty ? nil : caption
            }(),
            focus: nil              // TODO:
        )
        
        // upload + N * check upload
        // upload : check = 9 : 1
        let uploadTaskCount: Int64 = 540
        let checkUploadTaskCount: Int64 = 1
        let checkUploadTaskRetryLimit: Int64 = 60
        
        progress.totalUnitCount = uploadTaskCount + checkUploadTaskCount * checkUploadTaskRetryLimit
        progress.completedUnitCount = 0
        
        let attachmentUploadResponse: Mastodon.Response.Content<Mastodon.Entity.Attachment> = try await {
            do {
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [V2] upload attachment...")
                
                progress.addChild(query.progress, withPendingUnitCount: uploadTaskCount)
                return try await context.apiService.uploadMedia(
                    domain: context.authContext.mastodonAuthenticationBox.domain,
                    query: query,
                    mastodonAuthenticationBox: context.authContext.mastodonAuthenticationBox,
                    needsFallback: false
                ).singleOutput()
            } catch {
                // check needs fallback
                guard let apiError = error as? Mastodon.API.Error,
                      apiError.httpResponseStatus == .notFound
                else { throw error }
                
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [V1] upload attachment...")

                progress.addChild(query.progress, withPendingUnitCount: uploadTaskCount)
                return try await context.apiService.uploadMedia(
                    domain: context.authContext.mastodonAuthenticationBox.domain,
                    query: query,
                    mastodonAuthenticationBox: context.authContext.mastodonAuthenticationBox,
                    needsFallback: true
                ).singleOutput()
            }
        }()
        
        // check needs wait processing (until get the `url`)
        if attachmentUploadResponse.statusCode == 202 {
            // note:
            // the Mastodon server append the attachments in order by upload time
            // can not upload concurrency
            let waitProcessRetryLimit = checkUploadTaskRetryLimit
            var waitProcessRetryCount: Int64 = 0
            
            repeat {
                defer {
                    // make sure always count + 1
                    waitProcessRetryCount += checkUploadTaskCount
                }
                
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): check attachment process status")

                let attachmentStatusResponse = try await context.apiService.getMedia(
                    attachmentID: attachmentUploadResponse.value.id,
                    mastodonAuthenticationBox: context.authContext.mastodonAuthenticationBox
                ).singleOutput()
                progress.completedUnitCount += checkUploadTaskCount
                
                if let url = attachmentStatusResponse.value.url {
                    AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment process finish: \(url)")
                    
                    // escape here
                    progress.completedUnitCount = progress.totalUnitCount
                    return .mastodon(attachmentStatusResponse)
                    
                } else {
                    AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment processing. Retry \(waitProcessRetryCount)/\(waitProcessRetryLimit)")
                    await Task.sleep(1_000_000_000 * 3)     // 3s
                }
            } while waitProcessRetryCount < waitProcessRetryLimit
         
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment processing result discard due to exceed retry limit")
            throw AppError.badRequest
        } else {
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): upload attachment success: \(attachmentUploadResponse.value.url ?? "<nil>")")

            return .mastodon(attachmentUploadResponse)
        }
    }
}

extension AttachmentViewModel.Output {
    var asAttachment: Mastodon.Query.MediaAttachment {
        switch self {
        case .image(let data, let kind):
            switch kind {
            case .png:      return .png(data)
            case .jpg:      return .jpeg(data)
            }
        case .video(let url, _):
            return .other(url, fileExtension: url.pathExtension, mimeType: "video/mp4")
        }
    }
}
