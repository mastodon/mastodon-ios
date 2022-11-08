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
    
    public let id = UUID()
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    // input
    public let authContext: AuthContext
    public let input: Input
    @Published var caption = ""
    @Published var sizeLimit = SizeLimit()
    @Published public var isPreviewPresented = false
    
    // output
    @Published public private(set) var output: Output?
    @Published public private(set) var thumbnail: UIImage?      // original size image thumbnail
    @Published var error: Error?
    let progress = Progress()       // upload progress
    
    public init(
        authContext: AuthContext,
        input: Input
    ) {
        self.authContext = authContext
        self.input = input
        super.init()
        // end init
        
        defer {
            Task {
                await load(input: input)
            }
        }
        
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
    }
    
    deinit {
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
    
    public enum AttachmentError: Error {
        case invalidAttachmentType
        case attachmentTooLarge
    }

}

extension AttachmentViewModel {
    
    @MainActor
    private func load(input: Input) async {
        switch input {
        case .image(let image):
            guard let data = image.pngData() else {
                error = AttachmentError.invalidAttachmentType
                return
            }
            output = .image(data, imageKind: .png)
        case .url(let url):
            do {
                let output = try await AttachmentViewModel.load(url: url)
                self.output = output
            } catch {
                self.error = error
            }
        case .pickerResult(let pickerResult):
            do {
                let output = try await AttachmentViewModel.load(itemProvider: pickerResult.itemProvider)
                self.output = output
            } catch {
                self.error = error
            }
        case .itemProvider(let itemProvider):
            do {
                let output = try await AttachmentViewModel.load(itemProvider: itemProvider)
                self.output = output
            } catch {
                self.error = error
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

// MARK: - TypeIdentifiedItemProvider
extension AttachmentViewModel: TypeIdentifiedItemProvider {
    public static var typeIdentifier: String {
        // must in UTI format
        // https://developer.apple.com/library/archive/qa/qa1796/_index.html
        return "com.twidere.AttachmentViewModel"
    }
}

// MARK: - NSItemProviderWriting
extension AttachmentViewModel: NSItemProviderWriting {
    
    
    /// Attachment uniform type idendifiers
    ///
    /// The latest one for in-app drag and drop.
    /// And use generic `image` and `movie` type to
    /// allows transformable media in different formats
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [
            UTType.image.identifier,
            UTType.movie.identifier,
            AttachmentViewModel.typeIdentifier,
        ]
    }
    
    public var writableTypeIdentifiersForItemProvider: [String] {
        // should append elements in priority order from high to low
        var typeIdentifiers: [String] = []
        
        // FIXME: check jpg or png
        switch input {
        case .image:
            typeIdentifiers.append(UTType.png.identifier)
        case .url(let url):
            let _uti = UTType(filenameExtension: url.pathExtension)
            if let uti = _uti {
                if uti.conforms(to: .image) {
                    typeIdentifiers.append(UTType.png.identifier)
                } else if uti.conforms(to: .movie) {
                    typeIdentifiers.append(UTType.mpeg4Movie.identifier)
                }
            }
        case .pickerResult(let item):
            if item.itemProvider.isImage() {
                typeIdentifiers.append(UTType.png.identifier)
            } else if item.itemProvider.isMovie() {
                typeIdentifiers.append(UTType.mpeg4Movie.identifier)
            }
        case .itemProvider(let itemProvider):
            if itemProvider.isImage() {
                typeIdentifiers.append(UTType.png.identifier)
            } else if itemProvider.isMovie() {
                typeIdentifiers.append(UTType.mpeg4Movie.identifier)
            }
        }
        
        typeIdentifiers.append(AttachmentViewModel.typeIdentifier)
        
        return typeIdentifiers
    }
    
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        switch typeIdentifier {
        case AttachmentViewModel.typeIdentifier:
            do {
                let archiver = NSKeyedArchiver(requiringSecureCoding: false)
                try archiver.encodeEncodable(id, forKey: NSKeyedArchiveRootObjectKey)
                archiver.finishEncoding()
                let data = archiver.encodedData
                completionHandler(data, nil)
            } catch {
                assertionFailure()
                completionHandler(nil, nil)
            }
        default:
            break
        }
        
        let loadingProgress = Progress(totalUnitCount: 100)
        
        Publishers.CombineLatest(
            $output,
            $error
        )
        .sink { [weak self] output, error in
            guard let self = self else { return }
            
            // continue when load completed
            guard output != nil || error != nil else { return }
            
            switch output {
            case .image(let data, _):
                switch typeIdentifier {
                case UTType.png.identifier:
                    loadingProgress.completedUnitCount = 100
                    completionHandler(data, nil)
                default:
                    completionHandler(nil, nil)
                }
            case .video(let url, _):
                switch typeIdentifier {
                case UTType.png.identifier:
                    let _image = AttachmentViewModel.createThumbnailForVideo(url: url)
                    let _data = _image?.pngData()
                    loadingProgress.completedUnitCount = 100
                    completionHandler(_data, nil)
                case UTType.mpeg4Movie.identifier:
                    let task = URLSession.shared.dataTask(with: url) { data, response, error in
                        completionHandler(data, error)
                    }
                    task.progress.observe(\.fractionCompleted) { progress, change in
                        loadingProgress.completedUnitCount = Int64(100 * progress.fractionCompleted)
                    }
                    .store(in: &self.observations)
                    task.resume()
                default:
                    completionHandler(nil, nil)
                }
            case nil:
                completionHandler(nil, error)
            }
        }
        .store(in: &disposeBag)
        
        return loadingProgress
    }
    
}

extension NSItemProvider {
    fileprivate func isImage() -> Bool {
        return hasRepresentationConforming(
            toTypeIdentifier: UTType.image.identifier,
            fileOptions: []
        )
    }
    
    fileprivate func isMovie() -> Bool {
        return hasRepresentationConforming(
            toTypeIdentifier: UTType.movie.identifier,
            fileOptions: []
        )
    }
}
