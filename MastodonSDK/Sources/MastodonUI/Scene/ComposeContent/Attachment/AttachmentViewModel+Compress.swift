//
//  AttachmentViewModel+Compress.swift
//  
//
//  Created by MainasuK on 2022/11/11.
//

import os.log
import UIKit
import AVKit
import MastodonCore
import SessionExporter
import Kingfisher

extension AttachmentViewModel {
    func compressVideo(url: URL) async throws -> URL {
        let urlAsset = AVURLAsset(url: url)
        let exporter = NextLevelSessionExporter(withAsset: urlAsset)
        exporter.outputFileType = .mp4
        
        let isLandscape: Bool = {
            guard let track = urlAsset.tracks(withMediaType: .video).first else {
                return true
            }
            
            let size = track.naturalSize.applying(track.preferredTransform)
            return abs(size.width) >= abs(size.height)
        }()
        
        let outputURL = try FileManager.default.createTemporaryFileURL(
            filename: UUID().uuidString,
            pathExtension: url.pathExtension
        )
        exporter.outputURL = outputURL
        
        let compressionDict: [String: Any] = [
            AVVideoAverageBitRateKey: NSNumber(integerLiteral: 3000000), // 3000k
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel as String,
            AVVideoAverageNonDroppableFrameRateKey: NSNumber(floatLiteral: 30), // 30 FPS
        ]
        exporter.videoOutputConfiguration = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber(integerLiteral: isLandscape ? 1280 : 720),
            AVVideoHeightKey: NSNumber(integerLiteral: isLandscape ? 720 : 1280),
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: compressionDict
        ]
        exporter.audioOutputConfiguration = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: NSNumber(integerLiteral: 128000),  // 128k
            AVNumberOfChannelsKey: NSNumber(integerLiteral: 2),
            AVSampleRateKey: NSNumber(value: Float(44100))
        ]
        
        // needs set to LOW priority to prevent priority inverse issue
        let task = Task(priority: .utility) {
            _ = try await exportVideo(by: exporter)
        }
        _ = try await task.value
        
        return outputURL
    }
    
    private func exportVideo(by exporter: NextLevelSessionExporter) async throws -> URL {
        guard let outputURL = exporter.outputURL else {
            throw AppError.badRequest
        }
        return try await withCheckedThrowingContinuation { continuation in
            exporter.export(progressHandler: { progress in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.videoCompressProgress = Double(progress)
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: export progress: %.2f", ((#file as NSString).lastPathComponent), #line, #function, progress)
                }
            }, completionHandler: { result in
                switch result {
                case .success(let status):
                    switch status {
                    case .completed:
                        print("NextLevelSessionExporter, export completed, \(exporter.outputURL?.description ?? "")")
                        continuation.resume(with: .success(outputURL))
                    default:
                        if Task.isCancelled {
                            exporter.cancelExport()
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: cancel export", ((#file as NSString).lastPathComponent), #line, #function)
                        }
                        print("NextLevelSessionExporter, did not complete")
                    }
                case .failure(let error):
                    continuation.resume(with: .failure(error))
                }
            })
        }
    }   // end func
}

extension AttachmentViewModel {
    @AttachmentViewModelActor
    func compressImage(data: Data, sizeLimit: SizeLimit) throws -> Output {
        let maxPayloadSizeInBytes = max((sizeLimit.image ?? 10 * 1024 * 1024), 1 * 1024 * 1024)

        guard let image = KFCrossPlatformImage(data: data)?.kf.normalized,
              var imageData = image.kf.pngRepresentation()
        else {
            throw AttachmentError.invalidAttachmentType
        }
        
        repeat {
            guard let image = KFCrossPlatformImage(data: imageData) else {
                throw AttachmentError.invalidAttachmentType
            }

            if imageData.kf.imageFormat == .PNG {
                // A. png image
                if imageData.count > maxPayloadSizeInBytes {
                    guard let compressedJpegData = image.jpegData(compressionQuality: 0.8) else {
                        throw AttachmentError.invalidAttachmentType
                    }
                    os_log("%{public}s[%{public}ld], %{public}s: compress png %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
                    imageData = compressedJpegData
                } else {
                    os_log("%{public}s[%{public}ld], %{public}s: png %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024)
                    break
                }
            } else {
                // B. other image
                if imageData.count > maxPayloadSizeInBytes {
                    let targetSize = CGSize(width: image.size.width * 0.8, height: image.size.height * 0.8)
                    let scaledImage = image.kf.resize(to: targetSize)
                    guard let compressedJpegData = scaledImage.jpegData(compressionQuality: 0.8) else {
                        throw AttachmentError.invalidAttachmentType
                    }
                    os_log("%{public}s[%{public}ld], %{public}s: compress jpeg %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
                    imageData = compressedJpegData
                } else {
                    os_log("%{public}s[%{public}ld], %{public}s: jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024)
                    break
                }
            }
        } while (imageData.count > maxPayloadSizeInBytes)
        
        
        return .image(imageData, imageKind: imageData.kf.imageFormat == .PNG ? .png : .jpg)
    }
}

@globalActor actor AttachmentViewModelActor {
    static var shared = AttachmentViewModelActor()
}
