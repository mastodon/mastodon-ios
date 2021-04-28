//
//  MediaPreviewImageViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import os.log
import UIKit
import Combine

protocol MediaPreviewImageViewControllerDelegate: class {
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, tapGestureRecognizerDidTrigger tapGestureRecognizer: UITapGestureRecognizer)
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, longPressGestureRecognizerDidTrigger longPressGestureRecognizer: UILongPressGestureRecognizer)
}

final class MediaPreviewImageViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewImageViewModel!
    weak var delegate: MediaPreviewImageViewControllerDelegate?

    // let progressBarView = ProgressBarView()
    let previewImageView = MediaPreviewImageView()

    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        previewImageView.imageView.af.cancelImageRequest()
    }
}

extension MediaPreviewImageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        progressBarView.tintColor = .white
//        progressBarView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(progressBarView)
//        NSLayoutConstraint.activate([
//            progressBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            progressBarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            progressBarView.widthAnchor.constraint(equalToConstant: 120),
//            progressBarView.heightAnchor.constraint(equalToConstant: 44),
//        ])
        
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewImageView)
        NSLayoutConstraint.activate([
            previewImageView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            previewImageView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tapGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.tapGestureRecognizerHandler(_:)))
        longPressGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.longPressGestureRecognizerHandler(_:)))
        tapGestureRecognizer.require(toFail: previewImageView.doubleTapGestureRecognizer)
        tapGestureRecognizer.require(toFail: longPressGestureRecognizer)
        previewImageView.addGestureRecognizer(tapGestureRecognizer)
        previewImageView.addGestureRecognizer(longPressGestureRecognizer)
        
        switch viewModel.item {
        case .status(let meta):
//            progressBarView.isHidden = meta.thumbnail != nil
            previewImageView.imageView.af.setImage(
                withURL: meta.url,
                placeholderImage: meta.thumbnail,
                filter: nil,
                progress: { [weak self] progress in
                    guard let self = self else { return }
                    // self.progressBarView.progress.value = CGFloat(progress.fractionCompleted)
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: load %s progress: %.2f", ((#file as NSString).lastPathComponent), #line, #function, meta.url.debugDescription, progress.fractionCompleted)
                },
                imageTransition: .crossDissolve(0.3),
                runImageTransitionIfCached: false,
                completion: { [weak self] response in
                    guard let self = self else { return }
                    switch response.result {
                    case .success(let image):
                        //self.progressBarView.isHidden = true
                        self.previewImageView.imageView.image = image
                        self.previewImageView.setup(image: image, container: self.previewImageView, forceUpdate: true)
                    case .failure(let error):
                        // TODO:
                        break
                    }
                }
            )
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: setImage url: %s", ((#file as NSString).lastPathComponent), #line, #function, meta.url.debugDescription)
        case .local(let meta):
            // progressBarView.isHidden = true
            previewImageView.imageView.image = meta.image
            self.previewImageView.setup(image: meta.image, container: self.previewImageView, forceUpdate: true)
        }
    }
    
}

extension MediaPreviewImageViewController {
    
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaPreviewImageViewController(self, tapGestureRecognizerDidTrigger: sender)
    }
    
    @objc private func longPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaPreviewImageViewController(self, longPressGestureRecognizerDidTrigger: sender)
    }
    
}
