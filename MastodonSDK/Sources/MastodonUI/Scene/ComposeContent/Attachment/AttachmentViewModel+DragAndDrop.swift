//
//  AttachmentViewModel+DragAndDrop.swift
//  
//
//  Created by MainasuK on 2022/11/8.
//

import os.log
import UIKit
import Combine
import UniformTypeIdentifiers

// MARK: - TypeIdentifiedItemProvider
extension AttachmentViewModel: TypeIdentifiedItemProvider {
    public static var typeIdentifier: String {
        // must in UTI format
        // https://developer.apple.com/library/archive/qa/qa1796/_index.html
        return "org.joinmastodon.app.AttachmentViewModel"
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
