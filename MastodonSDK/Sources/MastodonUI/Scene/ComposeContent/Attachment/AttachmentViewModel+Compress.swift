//
//  AttachmentViewModel+Compress.swift
//
//
//  Created by MainasuK on 2022/11/11.
//

import UIKit
import AVKit
import CoreMedia
import MastodonCore
import SessionExporter
import Nuke

extension AttachmentViewModel {
    func compressVideo(url: URL) async throws -> URL {
        let urlAsset = AVURLAsset(url: url)

        // This is a workaround for a bug in NextLevelSessionExporter
        // @see https://github.com/NextLevel/NextLevelSessionExporter/issues/49
        // The following line should be removed then Issue 49 is fixed upstream
        urlAsset = try await assetByRemovingAPACTracks(from: urlAsset)

        guard let track = try await urlAsset.loadTracks(withMediaType: .video).first else {
            throw AttachmentError.invalidAttachmentType
        }

        let exporter = NextLevelSessionExporter(withAsset: urlAsset)
        exporter.outputFileType = .mp4

        let preferredSize = try await preferredSizeFor(
            track: track,
            maxLongestSide: 1280
        )

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
            AVVideoWidthKey: NSNumber(floatLiteral: preferredSize.width),
            AVVideoHeightKey: NSNumber(floatLiteral: preferredSize.height),
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

    private func assetByRemovingAPACTracks(from urlAsset: AVURLAsset) async throws -> AVAsset {
        let filteredAsset = AVMutableComposition()
        let kAudioFormatAPAC_FourCharCode: FourCharCode = 0x61706163 // 'apac'

        // Load all tracks from the original asset
        let allOriginalTracks = try await urlAsset.load(.tracks)

        for track in allOriginalTracks {
            var shouldAddTrack = true
            if track.mediaType == .audio {
                let formatDescriptions = try await track.load(.formatDescriptions)
                for formatDesc in formatDescriptions {
                    if CMFormatDescriptionGetMediaType(formatDesc) == kCMMediaType_Audio {
                        if CMFormatDescriptionGetMediaSubType(formatDesc) == kAudioFormatAPAC_FourCharCode {
                            shouldAddTrack = false
                            // Optional: Log that the track is being skipped
                            // print("AttachmentViewModel: Skipping APAC audio track ID \(track.trackID)")
                            break
                        }
                    }
                }
            }

            if shouldAddTrack {
                if let compositionTrack = filteredAsset.addMutableTrack(
                    withMediaType: track.mediaType,
                    preferredTrackID: kCMPersistentTrackID_Invalid // Auto-assign ID
                ) {
                    do {
                        let timeRange = try await track.load(.timeRange)
                        try compositionTrack.insertTimeRange(timeRange, of: track, at: .zero)

                        if track.mediaType == .video {
                            compositionTrack.preferredTransform = try await track.load(.preferredTransform)
                        }
                        if let langCode = try? await track.load(.languageCode) {
                             compositionTrack.languageCode = langCode
                        }
                        if let extLangTag = try? await track.load(.extendedLanguageTag) {
                             compositionTrack.extendedLanguageTag = extLangTag
                        }
                    } catch {
                        // Rethrow errors from track manipulation
                        // print("AttachmentViewModel: Error processing track \(track.trackID): \(error)")
                        throw error
                    }
                } else {
                    // Failed to add a track to the composition; this is a critical error.
                    // print("AttachmentViewModel: Failed to add mutable track for media type \(track.mediaType)")
                    throw AttachmentError.invalidAttachmentType // Or a more specific error
                }
            }
        }
        return filteredAsset
    }

    private func preferredSizeFor(track: AVAssetTrack, maxLongestSide: CGFloat) async throws -> CGSize {
        let trackSize = try await track.load(.naturalSize).applying(track.preferredTransform)
        let actualSize = CGSize(width: abs(trackSize.width), height: abs(trackSize.height))
        let isLandscape = actualSize.width >= actualSize.height

        switch isLandscape {
        case false: // portrait mode, needs height altered eventually
            if actualSize.height > maxLongestSide {
                // reduce height, keep aspect ratio
                return CGSize(width: (maxLongestSide / (actualSize.height/actualSize.width)), height: maxLongestSide)
            }
            return actualSize
        case true: // landscape mode, needs width altered eventually
            if actualSize.width > maxLongestSide {
               // reduce width, keep aspect ratio
               return CGSize(width: maxLongestSide, height: (maxLongestSide * (actualSize.height/actualSize.width)))
           }
            return actualSize
        }
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

        guard let image = UIImage(data: data)?.normalized(),
              var imageData = image.pngData()
        else {
            throw AttachmentError.invalidAttachmentType
        }

        repeat {
            guard let image = UIImage(data: imageData) else {
                throw AttachmentError.invalidAttachmentType
            }

            if AssetType(imageData) == .png {
                // A. png image
                if imageData.count > maxPayloadSizeInBytes {
                    guard let compressedJpegData = image.jpegData(compressionQuality: 0.8) else {
                        throw AttachmentError.invalidAttachmentType
                    }
                    imageData = compressedJpegData
                } else {
                    break
                }
            } else {
                // B. other image
                if imageData.count > maxPayloadSizeInBytes {
                    let targetSize = CGSize(width: image.size.width * 0.8, height: image.size.height * 0.8)
                    let scaledImage = image.resized(size: targetSize)
                    guard let compressedJpegData = scaledImage.jpegData(compressionQuality: 0.8) else {
                        throw AttachmentError.invalidAttachmentType
                    }
                    imageData = compressedJpegData
                } else {
                    break
                }
            }
        } while (imageData.count > maxPayloadSizeInBytes)


        return .image(imageData, imageKind: AssetType(imageData) == .png ? .png : .jpg)
    }
}

@globalActor actor AttachmentViewModelActor {
    static var shared = AttachmentViewModelActor()
}
