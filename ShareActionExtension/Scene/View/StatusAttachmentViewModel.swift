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
import MastodonSDK
import MastodonUI
import AVFoundation
import MobileCoreServices
import UniformTypeIdentifiers

final class StatusAttachmentViewModel: ObservableObject, Identifiable {

    let logger = Logger(subsystem: "StatusAttachmentViewModel", category: "logic")

    var disposeBag = Set<AnyCancellable>()

    let id = UUID()
    let itemProvider: NSItemProvider

    // input
    let file = CurrentValueSubject<Mastodon.Query.MediaAttachment?, Never>(nil)
    @Published var description = ""

    // output
    @Published var thumbnailImage: UIImage?
    @Published var error: Error?

    init(itemProvider: NSItemProvider) {
        self.itemProvider = itemProvider

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
//                    self.uploadStateMachine.enter(UploadState.Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] file in
                guard let self = self else { return }
                self.file.value = file
//                self.uploadStateMachine.enter(UploadState.Initial.self)
            }
            .store(in: &disposeBag)


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
    }

}

extension StatusAttachmentViewModel {
    enum AttachmentError: Error {
        case invalidAttachmentType
        case attachmentTooLarge
    }
}
