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
        imageView.pinToParent()
        
        imageView.image = viewModel.thumbnail
        
        let frame = AVMakeRect(aspectRatio: viewModel.aspectRatio, insideRect: view.bounds)
        preferredContentSize = frame.size
        
        imageView.af.setImage(
            withURL: viewModel.assetURL,
            placeholderImage: viewModel.thumbnail,
            imageTransition: .crossDissolve(0.2),
            runImageTransitionIfCached: false,
            completion: nil
        )
    }
    
}
