//
//  AttachmentViewModel+Compress.swift
//  
//
//  Created by MainasuK on 2022/11/11.
//

import UIKit
import AVKit

extension AttachmentViewModel {
    func comporessVideo(url: URL) async throws -> URL {
        let task = Task { () -> URL in
            let urlAsset = AVURLAsset(url: url)
            guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
                throw AttachmentError.invalidAttachmentType
            }
            let outputURL = try FileManager.default.createTemporaryFileURL(
                filename: UUID().uuidString,
                pathExtension: url.pathExtension
            )
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            await exportSession.export()
            return outputURL
        }
        
        self.compressVideoTask = task
        
        return try await task.value
    }
}
