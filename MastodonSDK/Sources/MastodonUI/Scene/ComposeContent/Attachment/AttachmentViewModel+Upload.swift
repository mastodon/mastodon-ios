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

extension AttachmentViewModel {
    public enum UploadState {
        case none
        case compressing
        case ready
        case uploading
        case fail
        case finish
    }
    
    struct UploadContext {
        let apiService: APIService
        let authContext: AuthContext
    }
    
    public typealias UploadResult = Mastodon.Entity.Attachment
}

extension AttachmentViewModel {
    @MainActor
    func upload(isRetry: Bool = false) async throws {
        do {
            let result = try await upload(
                context: .init(
                    apiService: self.api,
                    authContext: self.authContext
                ),
                isRetry: isRetry
            )
            update(uploadResult: result)
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    private func upload(context: UploadContext, isRetry: Bool) async throws -> UploadResult {
        if isRetry {
            guard uploadState == .fail else { throw AppError.badRequest }
            self.error = nil
            self.fractionCompleted = 0
        } else {
            guard uploadState == .ready else { throw AppError.badRequest }
        }
        do {
            update(uploadState: .uploading)
            let result = try await uploadMastodonMedia(
                context: context
            )
            update(uploadState: .finish)
            return result
        } catch {
            update(uploadState: .fail)
            throw error
        }
    }
    
    // MainActor is required here to trigger stream upload task
    @MainActor
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
            // can not upload parallels
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
                    return attachmentStatusResponse.value
                    
                } else {
                    AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment processing. Retry \(waitProcessRetryCount)/\(waitProcessRetryLimit)")
                    await Task.sleep(1_000_000_000 * 3)     // 3s
                }
            } while waitProcessRetryCount < waitProcessRetryLimit
         
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment processing result discard due to exceed retry limit")
            throw AppError.badRequest
        } else {
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): upload attachment success: \(attachmentUploadResponse.value.url ?? "<nil>")")

            return attachmentUploadResponse.value
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
