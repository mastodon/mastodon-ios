//
//  FLAnimatedImageView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-21.
//

import Foundation
import Combine
import Alamofire
import AlamofireImage
import FLAnimatedImage
import UIKit

private enum FLAnimatedImageViewAssociatedKeys {
    static var activeAvatarRequestURL = "FLAnimatedImageViewAssociatedKeys.activeAvatarRequestURL"
    static var avatarRequestCancellable = "FLAnimatedImageViewAssociatedKeys.avatarRequestCancellable"
}

extension FLAnimatedImageView {

    var activeAvatarRequestURL: URL? {
        get {
            objc_getAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.activeAvatarRequestURL) as? URL
        }
        set {
            objc_setAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.activeAvatarRequestURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var avatarRequestCancellable: AnyCancellable? {
        get {
            objc_getAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.avatarRequestCancellable) as? AnyCancellable
        }
        set {
            objc_setAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.avatarRequestCancellable, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func setImage(
        url: URL?,
        placeholder: UIImage?,
        scaleToSize: CGSize?,
        completion: ((UIImage?) -> Void)? = nil
    ) {
        // cancel task
        activeAvatarRequestURL = nil
        avatarRequestCancellable?.cancel()

        // set placeholder
        image = placeholder

        // set image
        guard let url = url else { return }
        activeAvatarRequestURL = url
        let avatarRequest = AF.request(url).publishData()
        avatarRequestCancellable = avatarRequest
            .sink { response in
                switch response.result {
                case .success(let data):
                    DispatchQueue.global().async {
                        let image: UIImage? = {
                            if let scaleToSize = scaleToSize {
                                return UIImage(data: data)?.af.imageScaled(to: scaleToSize, scale: UIScreen.main.scale)
                            } else {
                                return UIImage(data: data)
                            }
                        }()
                        let animatedImage = FLAnimatedImage(animatedGIFData: data)

                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            guard self.activeAvatarRequestURL == url else { return }
                            if let animatedImage = animatedImage {
                                self.animatedImage = animatedImage
                            } else {
                                self.image = image
                            }
                            completion?(image)
                        }
                    }
                case .failure:
                    completion?(nil)
                }
            }
    }
}
