//
//  AttachmentViewModel.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import os.log
import UIKit
import Combine
import PhotosUI
import Kingfisher
import MastodonCore

final public class AttachmentViewModel: NSObject, ObservableObject, Identifiable {

    static let logger = Logger(subsystem: "AttachmentViewModel", category: "ViewModel")
    let logger = Logger(subsystem: "AttachmentViewModel", category: "ViewModel")
    
    public let id = UUID()
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    // input
    public let api: APIService
    public let authContext: AuthContext
    public let input: Input
    @Published var caption = ""
    @Published var sizeLimit = SizeLimit()
    
    // output
    @Published public private(set) var output: Output?
    @Published public private(set) var thumbnail: UIImage?      // original size image thumbnail
    @Published public private(set) var outputSizeInByte: Int64 = 0
    
    @Published public var uploadResult: UploadResult?
    @Published var error: Error?

    let progress = Progress()       // upload progress
    @Published var fractionCompleted: Double = 0

    var displayLink: CADisplayLink!
    private var lastTimestamp: TimeInterval?
    private var lastUploadSizeInByte: Int64 = 0
    private var averageUploadSpeedInByte: Int64 = 0
    @Published var remainTimeLocalizedString: String?
    
    public init(
        api: APIService,
        authContext: AuthContext,
        input: Input
    ) {
        self.api = api
        self.authContext = authContext
        self.input = input
        super.init()
        // end init
        
        self.displayLink = CADisplayLink(
            target: self,
            selector: #selector(AttachmentViewModel.step(displayLink:))
        )
        displayLink.add(to: .current, forMode: .common)

        progress
            .observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
                guard let self = self else { return }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish progress \(progress.fractionCompleted)")
                self.fractionCompleted = progress.fractionCompleted
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
            .store(in: &observations)
        
        // Note: this observation is redundant if .fractionCompleted listener always emit event when reach 1.0 progress
        // progress
        //     .observe(\.isFinished, options: [.initial, .new]) { [weak self] progress, _ in
        //         guard let self = self else { return }
        //         self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish progress \(progress.fractionCompleted)")
        //         DispatchQueue.main.async {
        //             self.objectWillChange.send()
        //         }
        //     }
        //     .store(in: &observations)
        
        $output
            .map { output -> UIImage? in
                switch output {
                case .image(let data, _):
                    return UIImage(data: data)
                case .video(let url, _):
                    return AttachmentViewModel.createThumbnailForVideo(url: url)
                case .none:
                    return nil
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnail)
        
        defer {
            Task { @MainActor in
                do {
                    let output = try await load(input: input)
                    self.output = output
                    self.outputSizeInByte = output.asAttachment.sizeInByte.flatMap { Int64($0) } ?? 0
                    let uploadResult = try await self.upload(context: .init(
                        apiService: self.api,
                        authContext: self.authContext
                    ))
                    self.uploadResult = uploadResult
                } catch {
                    self.error = error
                }
            }   // end Task
        }
    }
    
    deinit {
        displayLink.invalidate()
        displayLink.remove(from: .current, forMode: .common)
        
        switch output {
        case .image:
            // FIXME:
            break
        case .video(let url, _):
            try? FileManager.default.removeItem(at: url)
        case nil :
            break
        }
    }
}

// calculate the upload speed
// ref: https://stackoverflow.com/a/3841706/3797903
extension AttachmentViewModel {
    
    static var SpeedSmoothingFactor = 0.4
    static let remainsTimeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
    
    @objc private func step(displayLink: CADisplayLink) {
        guard let lastTimestamp = self.lastTimestamp else {
            self.lastTimestamp = displayLink.timestamp
            self.lastUploadSizeInByte = Int64(Double(outputSizeInByte) * progress.fractionCompleted)
            return
        }

        let duration = displayLink.timestamp - lastTimestamp
        guard duration >= 1.0 else { return }       // update every 1 sec
        
        let old = self.lastUploadSizeInByte
        self.lastUploadSizeInByte = Int64(Double(outputSizeInByte) * progress.fractionCompleted)
        
        let newSpeed = self.lastUploadSizeInByte - old
        let lastAverageSpeed = self.averageUploadSpeedInByte
        let newAverageSpeed = Int64(AttachmentViewModel.SpeedSmoothingFactor * Double(newSpeed) + (1 - AttachmentViewModel.SpeedSmoothingFactor) * Double(lastAverageSpeed))
        
        let remainSizeInByte = Double(outputSizeInByte) * (1 - progress.fractionCompleted)
        
        let speed = Double(newAverageSpeed)
        if speed != .zero {
            // estimate by speed
            let uploadRemainTimeInSecond = remainSizeInByte / speed
            // estimate by progress 1s for 10%
            let remainPercentage = 1 - progress.fractionCompleted
            let estimateRemainTimeByProgress = remainPercentage / 0.1
            // max estimate
            let remainTimeInSecond = max(estimateRemainTimeByProgress, uploadRemainTimeInSecond)
            
            let string = AttachmentViewModel.remainsTimeFormatter.localizedString(fromTimeInterval: remainTimeInSecond)
            remainTimeLocalizedString = string
            // print("remains: \(remainSizeInByte), speed: \(newAverageSpeed), \(string)")
        } else {
            remainTimeLocalizedString = nil
        }
        
        self.lastTimestamp = displayLink.timestamp
        self.averageUploadSpeedInByte = newAverageSpeed
    }
}

extension AttachmentViewModel {
    public enum Input: Hashable {
        case image(UIImage)
        case url(URL)
        case pickerResult(PHPickerResult)
        case itemProvider(NSItemProvider)
    }
    
    public enum Output {
        case image(Data, imageKind: ImageKind)
        // case gif(Data)
        case video(URL, mimeType: String)    // assert use file for video only
        
        public enum ImageKind {
            case png
            case jpg
        }
    }
        
    public struct SizeLimit {
        public let image: Int
        public let gif: Int
        public let video: Int
        
        public init(
            image: Int = 5 * 1024 * 1024,           // 5 MiB,
            gif: Int = 15 * 1024 * 1024,            // 15 MiB,
            video: Int = 512 * 1024 * 1024          // 512 MiB
        ) {
            self.image = image
            self.gif = gif
            self.video = video
        }
    }
    
    public enum AttachmentError: Error, LocalizedError {
        case invalidAttachmentType
        case attachmentTooLarge
        
        public var errorDescription: String? {
            switch self {
            case .invalidAttachmentType:
                return "Can not regonize this media attachment" // TODO: i18n
            case .attachmentTooLarge:
                return "Attachment too large"
            }
        }
    }

}





