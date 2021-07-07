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
import AlamofireImage

final class PhotoLibraryService: NSObject {

}

extension PhotoLibraryService {
    
    enum PhotoLibraryError: Error {
        case noPermission
    }

}

extension PhotoLibraryService {
    
    func saveImage(url: URL) -> AnyPublisher<UIImage, Error> {
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) != .denied else {
            return Fail(error: PhotoLibraryError.noPermission).eraseToAnyPublisher()
        }

        return processImage(url: url)
            .handleEvents(receiveOutput: { image in
                self.save(image: image)
            })
            .eraseToAnyPublisher()
    }

    func copyImage(url: URL) -> AnyPublisher<UIImage, Error> {
        return processImage(url: url)
            .handleEvents(receiveOutput: { image in
                UIPasteboard.general.image = image
            })
            .eraseToAnyPublisher()
    }

    func processImage(url: URL) -> AnyPublisher<UIImage, Error> {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

        return Future<UIImage, Error> { promise in
            ImageDownloader.default.download(URLRequest(url: url), completion: { response in
                switch response.result {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription, error.localizedDescription)
                    promise(.failure(error))
                case .success(let image):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s success", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription)
                    promise(.success(image))
                }
            })
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
    
    func save(image: UIImage, withNotificationFeedback: Bool = false) {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(PhotoLibraryService.image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
        
        // assert no error
        if withNotificationFeedback {
            let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
            notificationFeedbackGenerator.notificationOccurred(.success)
        }
    }

    func copy(image: UIImage, withNotificationFeedback: Bool = false) {
        UIPasteboard.general.image = image

        // assert no error
        if withNotificationFeedback {
            let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
            notificationFeedbackGenerator.notificationOccurred(.success)
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // TODO: notify banner
    }
    
}
