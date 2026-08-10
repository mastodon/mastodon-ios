// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import AlamofireImage
import SDWebImage

@MainActor
@Observable class CacheOverviewManager {
    
    private(set) var currentState: CalculationState = .ready(calculatedBytes: nil)
    
    enum CalculationState {
        case calculating
        case purging
        case ready(calculatedBytes: Int?)
        
        var isReady: Bool {
            switch self {
            case .calculating, .purging: return false
            case .ready: return true
            }
        }
    }
    
    init() {
        recalculate()
    }
    
    public let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        return formatter
    }()
    
    public func recalculate() {
        guard currentState.isReady else { return }
        currentState = .calculating
        Task {
            let currentDiskUsageBytes = await calculateCurrentDiskUsage()
            currentState = .ready(calculatedBytes: currentDiskUsageBytes)
        }
    }
    
    public func purgeAllCaches() {
        guard currentState.isReady else { return }
        currentState = .purging
        Task {
            ImageDownloader.defaultURLCache().removeAllCachedResponses()
            
            await withCheckedContinuation { continuation in
                SDImageCache.shared.clearDisk {
                    continuation.resume()
                }
            }
            
            await self.purgeTempDir()
            currentState = .ready(calculatedBytes: nil)
            self.recalculate()
        }
    }
    
    private func purgeTempDir() async {
        await Task.detached {
            let fileManager = FileManager.default
            for tempFile in CacheOverviewManager.synchronousTempDirectoryFileInfo() {
                try? fileManager.removeItem(at: tempFile.url)
            }
        }.value
    }
    
    private func calculateCurrentDiskUsage() async -> Int {
        let alamoFireDiskBytes = ImageDownloader.defaultURLCache().currentDiskUsage
        
        let sdImageDiskBytes = await withCheckedContinuation { continuation in
            SDImageCache.shared.calculateSize() { _, totalSize in
                continuation.resume(returning: Int(totalSize))
            }
        }
        
        let tempFilesDiskBytes = await calculateTmpDirSize()
        
        return alamoFireDiskBytes + sdImageDiskBytes + tempFilesDiskBytes
    }
    
    private func calculateTmpDirSize() async -> Int {
        let tempUrls = await tempDirectoryFileInfo()
        let tempFilesDiskBytes = tempUrls.reduce(into: 0) { partialResult, element in
            partialResult += element.size
        }
        return tempFilesDiskBytes
    }
    
    private func tempDirectoryFileInfo() async -> [(url: URL, size: Int) ] {
        return await Task.detached { CacheOverviewManager.synchronousTempDirectoryFileInfo() }.value
    }
    
    private nonisolated static func synchronousTempDirectoryFileInfo() -> [(url: URL, size: Int) ] {
        let fileManager = FileManager.default
        let temporaryDirectoryURL = fileManager.temporaryDirectory
        let fileKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey]
        
        guard let directoryEnumerator = fileManager.enumerator(
            at: temporaryDirectoryURL,
            includingPropertiesForKeys: Array(fileKeys),
            options: .skipsHiddenFiles) else { return [] }
        
        var result = [(URL, Int)]()
        for case let fileURL as URL in directoryEnumerator {
            guard let values = try? fileURL.resourceValues(forKeys: fileKeys), values.isDirectory == false, let fileSize = values.fileSize else { continue }
            result.append((fileURL, fileSize))
        }
        return result
    }
}
