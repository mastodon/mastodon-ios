//
//  FLAnimatedImageView.swift
//  FLAnimatedImageView
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Combine
import Alamofire
import AlamofireImage
import FLAnimatedImage

private enum FLAnimatedImageViewAssociatedKeys {
    static var activeAvatarRequestURL = "FLAnimatedImageViewAssociatedKeys.activeAvatarRequestURL"
    static var avatarRequestCancellable = "FLAnimatedImageViewAssociatedKeys.avatarRequestCancellable"
}

extension FLAnimatedImageView {
    
    public var activeAvatarRequestURL: URL? {
        get {
            objc_getAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.activeAvatarRequestURL) as? URL
        }
        set {
            objc_setAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.activeAvatarRequestURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var avatarRequestCancellable: AnyCancellable? {
        get {
            objc_getAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.avatarRequestCancellable) as? AnyCancellable
        }
        set {
            objc_setAssociatedObject(self, &FLAnimatedImageViewAssociatedKeys.avatarRequestCancellable, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func setImage(
        url: URL?,
        placeholder: UIImage? = nil,
        scaleToSize: CGSize? = nil
    ) {
        // cancel task
        cancelTask()
        
        // set image
        guard let url else {
            DispatchQueue.main.async { [weak self] in
                self?.image = placeholder
            }
            return
        }

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
                            if self.activeAvatarRequestURL == url {
                                if let animatedImage = animatedImage {
                                    self.animatedImage = animatedImage
                                } else {
                                    self.image = image
                                }
                            }
                        }
                    }
                case .failure:
                    DispatchQueue.main.async { [weak self] in
                        self?.image = placeholder
                    }
                }
            }
    }
    
    public func cancelTask() {
        activeAvatarRequestURL = nil
        avatarRequestCancellable?.cancel()
    }
}
