//
//  ContextMenuImagePreviewViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-30.
//

import func AVFoundation.AVMakeRect
import UIKit
import Combine

final class ContextMenuImagePreviewViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    var viewModel: ContextMenuImagePreviewViewModel!

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()

}

extension ContextMenuImagePreviewViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        imageView.image = viewModel.thumbnail
        
        let frame = AVMakeRect(aspectRatio: viewModel.aspectRatio, insideRect: view.bounds)
        preferredContentSize = frame.size
        
        viewModel.url
            .sink { [weak self] url in
                guard let self = self else { return }
                guard let url = url else { return }
                self.imageView.af.setImage(
                    withURL: url,
                    placeholderImage: self.viewModel.thumbnail,
                    imageTransition: .crossDissolve(0.2),
                    runImageTransitionIfCached: true,
                    completion: nil
                )
            }
            .store(in: &disposeBag)
    }
    
}
