//
//  StatusAttachmentViewModel.swift
//  ShareActionExtension
//
//  Created by MainasuK Cirno on 2021-7-19.
//

import os.log
import Foundation
import SwiftUI
import Combine
import CoreDataStack
import MastodonSDK
import MastodonUI
import AVFoundation
import GameplayKit
import MobileCoreServices
import UniformTypeIdentifiers
import MastodonAsset
import MastodonCore
import MastodonLocalization

protocol StatusAttachmentViewModelDelegate: AnyObject {
    func statusAttachmentViewModel(_ viewModel: StatusAttachmentViewModel, uploadStateDidChange state: StatusAttachmentViewModel.UploadState?)
}

final class StatusAttachmentViewModel: ObservableObject, Identifiable {

    static let photoFillSplitImage = Asset.Connectivity.photoFillSplit.image.withRenderingMode(.alwaysTemplate)
    static let videoSplashImage: UIImage = {
        let image = UIImage(systemName: "video.slash")!.withConfiguration(UIImage.SymbolConfiguration(pointSize: 64))
        return image
    }()

    let logger = Logger(subsystem: "StatusAttachmentViewModel", category: "logic")

    weak var delegate: StatusAttachmentViewModelDelegate?
    var disposeBag = Set<AnyCancellable>()

    let id = UUID()
    let itemProvider: NSItemProvider

    // input
    let api: APIService
    let file = CurrentValueSubject<Mastodon.Query.MediaAttachment?, Never>(nil)
    let authentication = CurrentValueSubject<MastodonAuthentication?, Never>(nil)
    @Published var descriptionContent = ""

    // output
    let attachment = CurrentValueSubject<Mastodon.Entity.Attachment?, Never>(nil)
    @Published var thumbnailImage: UIImage?
    @Published var descriptionPlaceholder = ""
    @Published var isUploading = true
    @Published var progressViewTintColor = UIColor.systemFill
    @Published var error: Error?
    @Published var errorPrompt: String?
    @Published var errorPromptImage: UIImage = StatusAttachmentViewModel.photoFillSplitImage

    private(set) lazy var uploadStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            UploadState.Initial(viewModel: self),
            UploadState.Uploading(viewModel: self),
            UploadState.Fail(viewModel: self),
            UploadState.Finish(viewModel: self),
        ])
        stateMachine.enter(UploadState.Initial.self)
        return stateMachine
    }()
    lazy var uploadStateMachineSubject = CurrentValueSubject<StatusAttachmentViewModel.UploadState?, Never>(nil)

    init(
        api: APIService,
        itemProvider: NSItemProvider
    ) {
        self.api = api
        self.itemProvider = itemProvider

        // bind attachment from item provider
        Just(itemProvider)
            .receive(on: DispatchQueue.main)
            .flatMap { result -> AnyPublisher<Mastodon.Query.MediaAttachment?, Error> in
                if itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.image.identifier, fileOptions: []) {
                    return ItemProviderLoader.loadImageData(from: result).eraseToAnyPublisher()
                }
                if itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.movie.identifier, fileOptions: []) {
                    return ItemProviderLoader.loadVideoData(from: result).eraseToAnyPublisher()
                }
                return Fail(error: AttachmentError.invalidAttachmentType).eraseToAnyPublisher()
            }
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.error = error
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

        // bind progress view tint color
        $thumbnailImage
            .receive(on: DispatchQueue.main)
            .map { image -> UIColor in
                guard let image = image else { return .systemFill }
                switch image.domainLumaCoefficientsStyle {
                case .light:
                    return UIColor.black.withAlphaComponent(0.8)
                default:
                    return UIColor.white.withAlphaComponent(0.8)
                }
            }
            .assign(to: &$progressViewTintColor)

        // bind description placeholder and error prompt image
        file
            .receive(on: DispatchQueue.main)
            .sink { [weak self] file in
                guard let self = self else { return }
                guard let file = file else { return }
                switch file {
                case .jpeg, .png, .gif:
                    self.descriptionPlaceholder = L10n.Scene.Compose.Attachment.descriptionPhoto
                    self.errorPromptImage = StatusAttachmentViewModel.photoFillSplitImage
                case .other:
                    self.descriptionPlaceholder = L10n.Scene.Compose.Attachment.descriptionVideo
                    self.errorPromptImage = StatusAttachmentViewModel.videoSplashImage
                }
            }
            .store(in: &disposeBag)

        // bind thumbnail image
        file
            .receive(on: DispatchQueue.main)
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
                        self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): thumbnail generate fail: \(error.localizedDescription)")
                        return nil
                    }
                }
            }
            .assign(to: &$thumbnailImage)

        // bind state and error
        Publishers.CombineLatest(
            uploadStateMachineSubject,
            $error
        )
        .sink { [weak self] state, error in
            guard let self = self else { return }
            // trigger delegate
            self.delegate?.statusAttachmentViewModel(self, uploadStateDidChange: state)

            // set error prompt
            if let error = error {
                self.isUploading = false
                self.errorPrompt = error.localizedDescription
            } else {
                guard let state = state else { return }
                switch state {
                case is UploadState.Finish:
                    self.isUploading = false
                case is UploadState.Fail:
                    self.isUploading = false
                    // FIXME: not display
                    self.errorPrompt = {
                        guard let file = self.file.value else {
                            return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.photo)
                        }
                        switch file {
                        case .jpeg, .png, .gif:
                            return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.photo)
                        case .other:
                            return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.video)
                        }
                    }()
                default:
                    break
                }
            }
        }
        .store(in: &disposeBag)

        // trigger delegate when authentication get new value
        authentication
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authentication in
                guard let self = self else { return }
                guard authentication != nil else { return }
                self.delegate?.statusAttachmentViewModel(self, uploadStateDidChange: self.uploadStateMachineSubject.value)
            }
            .store(in: &disposeBag)
    }

}

extension StatusAttachmentViewModel {
    enum AttachmentError: Error {
        case invalidAttachmentType
        case attachmentTooLarge
    }
}
