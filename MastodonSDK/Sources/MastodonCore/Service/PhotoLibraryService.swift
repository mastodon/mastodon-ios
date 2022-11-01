//
//  PhotoLibraryService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-29.
//

import os.log
import UIKit
import Combine
import Photos
import Alamofire
import AlamofireImage

public final class PhotoLibraryService: NSObject {

}

extension PhotoLibraryService {
    
    public enum PhotoLibraryError: Error {
        case noPermission
        case badPayload
    }

    public enum ImageSource {
        case url(URL)
        case image(UIImage)
    }

}

extension PhotoLibraryService {

    public func save(imageSource source: ImageSource) -> AnyPublisher<Void, Error> {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()


        let imageDataPublisher: AnyPublisher<Data, Error> = {
            switch source {
            case .url(let url):
                return PhotoLibraryService.fetchImageData(url: url)
            case .image(let image):
                return PhotoLibraryService.fetchImageData(image: image)
            }
        }()

        return imageDataPublisher
            .flatMap { data in
                PhotoLibraryService.save(imageData: data)
            }
            .handleEvents(receiveSubscription: { _ in
                impactFeedbackGenerator.impactOccurred()
            }, receiveCompletion: { completion in
                switch completion {
                case .failure:
                    notificationFeedbackGenerator.notificationOccurred(.error)
                case .finished:
                    notificationFeedbackGenerator.notificationOccurred(.success)
                }
            })
            .eraseToAnyPublisher()
    }

}

extension PhotoLibraryService {

    public func copy(imageSource source: ImageSource) -> AnyPublisher<Void, Error> {

        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

        let imageDataPublisher: AnyPublisher<Data, Error> = {
            switch source {
            case .url(let url):
                return PhotoLibraryService.fetchImageData(url: url)
            case .image(let image):
                return PhotoLibraryService.fetchImageData(image: image)
            }
        }()

        return imageDataPublisher
            .flatMap { data in
                PhotoLibraryService.copy(imageData: data)
            }
            .handleEvents(receiveSubscription: { _ in
                impactFeedbackGenerator.impactOccurred()
            }, receiveCompletion: { completion in
                switch completion {
                case .failure:
                    notificationFeedbackGenerator.notificationOccurred(.error)
                case .finished:
                    notificationFeedbackGenerator.notificationOccurred(.success)
                }
            })
            .eraseToAnyPublisher()
    }
}

extension PhotoLibraryService {

    static func fetchImageData(url: URL) -> AnyPublisher<Data, Error> {
        AF.request(url).publishData()
            .tryMap { response in
                switch response.result {
                case .success(let data):
                    return data
                case .failure(let error):
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

    static func fetchImageData(image: UIImage) -> AnyPublisher<Data, Error> {
        return Future<Data, Error> { promise in
            DispatchQueue.global().async {
                let imageData = image.pngData()
                DispatchQueue.main.async {
                    if let imageData = imageData {
                        promise(.success(imageData))
                    } else {
                        promise(.failure(PhotoLibraryError.badPayload))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    static func save(imageData: Data) -> AnyPublisher<Void, Error> {
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) != .denied else {
            return Fail(error: PhotoLibraryError.noPermission).eraseToAnyPublisher()
        }

        return Future<Void, Error> { promise in
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: imageData, options: nil)
            } completionHandler: { isSuccess, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(Void()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    static func copy(imageData: Data) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            DispatchQueue.global().async {
                let image = UIImage(data: imageData, scale: UIScreen.main.scale)
                DispatchQueue.main.async {
                    if let image = image {
                        UIPasteboard.general.image = image
                        promise(.success(Void()))
                    } else {
                        promise(.failure(PhotoLibraryError.badPayload))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

}
