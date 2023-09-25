//
//  MastodonAttachmentService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit
import Combine
import PhotosUI
import GameplayKit
import MobileCoreServices
import MastodonSDK

public protocol MastodonAttachmentServiceDelegate: AnyObject {
    func mastodonAttachmentService(_ service: MastodonAttachmentService, uploadStateDidChange state: MastodonAttachmentService.UploadState?)
}

public final class MastodonAttachmentService {
    
    public var disposeBag = Set<AnyCancellable>()
    public weak var delegate: MastodonAttachmentServiceDelegate?
    
    public let identifier = UUID()
        
    // input
    public let context: AppContext
    public var authenticationBox: MastodonAuthenticationBox?
    public let file = CurrentValueSubject<Mastodon.Query.MediaAttachment?, Never>(nil)
    public let description = CurrentValueSubject<String?, Never>(nil)
    
    // output
    public let thumbnailImage = CurrentValueSubject<UIImage?, Never>(nil)
    public let attachment = CurrentValueSubject<Mastodon.Entity.Attachment?, Never>(nil)
    public let error = CurrentValueSubject<Error?, Never>(nil)
    
    public private(set) lazy var uploadStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            UploadState.Initial(service: self),
            UploadState.Uploading(service: self),
            UploadState.Processing(service: self),
            UploadState.Fail(service: self),
            UploadState.Finish(service: self),
        ])
        stateMachine.enter(UploadState.Initial.self)
        return stateMachine
    }()
    public lazy var uploadStateMachineSubject = CurrentValueSubject<MastodonAttachmentService.UploadState?, Never>(nil)

    public init(
        context: AppContext,
        pickerResult: PHPickerResult,
        initialAuthenticationBox: MastodonAuthenticationBox?
    ) {
        self.context = context
        self.authenticationBox = initialAuthenticationBox
        // end init
        
        setupServiceObserver()
        
        Just(pickerResult)
            .flatMap { result -> AnyPublisher<Mastodon.Query.MediaAttachment?, Error> in
                if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.image.identifier, fileOptions: []) {
                    return ItemProviderLoader.loadImageData(from: result).eraseToAnyPublisher()
                }
                if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.movie.identifier, fileOptions: []) {
                    return ItemProviderLoader.loadVideoData(from: result).eraseToAnyPublisher()
                }
                return Fail(error: AttachmentError.invalidAttachmentType).eraseToAnyPublisher()
            }
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.error.value = error
                    self.uploadStateMachine.enter(UploadState.Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] file in
                guard let self = self else { return }
                self.file.value = file
                self.uploadStateMachine.enter(UploadState.Initial.self)
            }
            .store(in: &disposeBag)
    }
    
    public init(
        context: AppContext,
        image: UIImage,
        initialAuthenticationBox: MastodonAuthenticationBox?
    ) {
        self.context = context
        self.authenticationBox = initialAuthenticationBox
        // end init
        
        setupServiceObserver()
        
        file.value = .jpeg(image.jpegData(compressionQuality: 0.75))
        uploadStateMachine.enter(UploadState.Initial.self)
    }
    
    public init(
        context: AppContext,
        documentURL: URL,
        initialAuthenticationBox: MastodonAuthenticationBox?
    ) {
        self.context = context
        self.authenticationBox = initialAuthenticationBox
        // end init
        
        setupServiceObserver()
        
        Just(documentURL)
            .flatMap { documentURL -> AnyPublisher<Mastodon.Query.MediaAttachment, Error> in
                return MastodonAttachmentService.loadAttachment(url: documentURL)
            }
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.error.value = error
                    self.uploadStateMachine.enter(UploadState.Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] file in
                guard let self = self else { return }
                self.file.value = file
                self.uploadStateMachine.enter(UploadState.Initial.self)
            }
            .store(in: &disposeBag)

        uploadStateMachine.enter(UploadState.Initial.self)
    }
    
    private func setupServiceObserver() {
        uploadStateMachineSubject
            .sink { [weak self] state in
                guard let self = self else { return }
                self.delegate?.mastodonAttachmentService(self, uploadStateDidChange: state)
            }
            .store(in: &disposeBag)
        
        
        file
            .map { file -> UIImage? in
                guard let file = file else {
                    return nil
                }
                
                switch file {
                case .jpeg(let data), .png(let data):
                    return data.flatMap { UIImage(data: $0) }
                case .gif:
                    // TODO:
                    return nil
                case .other(let url, _, _):
                    guard let url = url, FileManager.default.fileExists(atPath: url.path) else { return nil }
                    let asset = AVURLAsset(url: url)
                    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
                    assetImageGenerator.appliesPreferredTrackTransform = true   // fix orientation
                    do {
                        let cgImage = try assetImageGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                        let image = UIImage(cgImage: cgImage)
                        return image
                    } catch {
                        return nil
                    }
                }
            }
            .assign(to: \.value, on: thumbnailImage)
            .store(in: &disposeBag)
    }
    
    
}

extension MastodonAttachmentService {
    public enum AttachmentError: Error {
        case invalidAttachmentType
        case attachmentTooLarge
    }
}

extension MastodonAttachmentService {
    // FIXME: needs reset state for multiple account posting support
    func uploading(mastodonAuthenticationBox: MastodonAuthenticationBox) -> Bool {
        authenticationBox = mastodonAuthenticationBox
        return uploadStateMachine.enter(UploadState.self)
    }
}

extension MastodonAttachmentService: Equatable, Hashable {
    
    public static func == (lhs: MastodonAttachmentService, rhs: MastodonAttachmentService) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
}

extension MastodonAttachmentService {
    
    private static func createWorkingQueue() -> DispatchQueue {
        return DispatchQueue(label: "org.joinmastodon.app.MastodonAttachmentService.\(UUID().uuidString)")
    }
    
    static func loadAttachment(url: URL) -> AnyPublisher<Mastodon.Query.MediaAttachment, Error> {
        guard let uti = UTType(filenameExtension: url.pathExtension) else {
            return Fail(error: AttachmentError.invalidAttachmentType).eraseToAnyPublisher()
        }
        
        if uti.conforms(to: .image) {
            return loadImageAttachment(url: url)
        } else if uti.conforms(to: .movie) {
            return loadVideoAttachment(url: url)
        } else {
            return Fail(error: AttachmentError.invalidAttachmentType).eraseToAnyPublisher()
        }
    }
    
    static func loadImageAttachment(url: URL) -> AnyPublisher<Mastodon.Query.MediaAttachment, Error> {
        Future<Mastodon.Query.MediaAttachment, Error> { promise in
            createWorkingQueue().async {
                do {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    let imageData = try Data(contentsOf: url)
                    promise(.success(.jpeg(imageData)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func loadVideoAttachment(url: URL) -> AnyPublisher<Mastodon.Query.MediaAttachment, Error> {
        Future<Mastodon.Query.MediaAttachment, Error> { promise in
            createWorkingQueue().async {
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let fileName = UUID().uuidString
                let tempDirectoryURL = FileManager.default.temporaryDirectory
                let fileURL = tempDirectoryURL.appendingPathComponent(fileName).appendingPathExtension(url.pathExtension)
                do {
                    try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    try FileManager.default.copyItem(at: url, to: fileURL)
                    let file = Mastodon.Query.MediaAttachment.other(fileURL, fileExtension: fileURL.pathExtension, mimeType: UTType.movie.preferredMIMEType ?? "video/mp4")
                    promise(.success(file))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
}
