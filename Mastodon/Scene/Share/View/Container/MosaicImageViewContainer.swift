//
//  MosaicImageViewContainer.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-23.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit

protocol MosaicImageViewContainerPresentable: class {
    var mosaicImageViewContainer: MosaicImageViewContainer { get }
}

protocol MosaicImageViewContainerDelegate: class {
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int)
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)

}

final class MosaicImageViewContainer: UIView {

    weak var delegate: MosaicImageViewContainerDelegate?
    
    let container = UIStackView()
    var imageViews: [UIImageView] = [] {
        didSet {
            imageViews.forEach { imageView in
                imageView.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer.singleTapGestureRecognizer
                tapGesture.addTarget(self, action: #selector(MosaicImageViewContainer.photoTapGestureRecognizerHandler(_:)))
                imageView.addGestureRecognizer(tapGesture)
            }
        }
    }
    
    let contentWarningOverlayView: ContentWarningOverlayView = {
        let contentWarningOverlayView = ContentWarningOverlayView()
        return contentWarningOverlayView
    }()
    
    private var containerHeightLayoutConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MosaicImageViewContainer: ContentWarningOverlayViewDelegate {
    func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView) {
        self.delegate?.mosaicImageViewContainer(self, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
}

extension MosaicImageViewContainer {
    
    private func _init() {
        contentWarningOverlayView.delegate = self
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .horizontal
        container.distribution = .fillEqually
        addSubview(container)
        containerHeightLayoutConstraint = container.heightAnchor.constraint(equalToConstant: 162).priority(.required - 1)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
            containerHeightLayoutConstraint
        ])
        
        addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            contentWarningOverlayView.topAnchor.constraint(equalTo: container.topAnchor),
            contentWarningOverlayView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            contentWarningOverlayView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }
    
}

extension MosaicImageViewContainer {
    
    func reset() {
        container.arrangedSubviews.forEach { subview in
            container.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        container.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        contentWarningOverlayView.removeFromSuperview()
        contentWarningOverlayView.blurVisualEffectView.effect = ContentWarningOverlayView.blurVisualEffect
        contentWarningOverlayView.vibrancyVisualEffectView.alpha = 1.0
        imageViews = []
        
        container.spacing = 1
    }
    
    func setupImageView(aspectRatio: CGSize, maxSize: CGSize) -> UIImageView {
        reset()
                
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(contentView)
        
        let rect = AVMakeRect(
            aspectRatio: aspectRatio,
            insideRect: CGRect(origin: .zero, size: maxSize)
        )

        let imageView = UIImageView()
        imageViews.append(imageView)
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = ContentWarningOverlayView.cornerRadius
        imageView.layer.cornerCurve = .continuous
        imageView.contentMode = .scaleAspectFill
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: floor(rect.width)).priority(.required - 1),
        ])
        containerHeightLayoutConstraint.constant = floor(rect.height)
        containerHeightLayoutConstraint.isActive = true
        
        addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            contentWarningOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            contentWarningOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            contentWarningOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])

        return imageView
    }
    
    func setupImageViews(count: Int, maxHeight: CGFloat) -> [UIImageView] {
        reset()
        guard count > 1 else {
            return []
        }
        
        containerHeightLayoutConstraint.constant = maxHeight
        containerHeightLayoutConstraint.isActive = true
        
        let contentLeftStackView = UIStackView()
        let contentRightStackView = UIStackView()
        [contentLeftStackView, contentRightStackView].forEach { stackView in
            stackView.axis = .vertical
            stackView.distribution = .fillEqually
            stackView.spacing = 1
        }
        container.addArrangedSubview(contentLeftStackView)
        container.addArrangedSubview(contentRightStackView)
        
        var imageViews: [UIImageView] = []
        for _ in 0..<count {
            imageViews.append(UIImageView())
        }
        self.imageViews.append(contentsOf: imageViews)
        imageViews.forEach { imageView in
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = ContentWarningOverlayView.cornerRadius
            imageView.layer.cornerCurve = .continuous
            imageView.contentMode = .scaleAspectFill
        }
        if count == 2 {
            contentLeftStackView.addArrangedSubview(imageViews[0])
            contentRightStackView.addArrangedSubview(imageViews[1])
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .rightToLeft:
                imageViews[1].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageViews[0].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            default:
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            }
            
        } else if count == 3 {
            contentLeftStackView.addArrangedSubview(imageViews[0])
            contentRightStackView.addArrangedSubview(imageViews[1])
            contentRightStackView.addArrangedSubview(imageViews[2])
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .rightToLeft:
                imageViews[0].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                imageViews[1].layer.maskedCorners = [.layerMinXMinYCorner]
                imageViews[2].layer.maskedCorners = [.layerMinXMaxYCorner]
            default:
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]
            }
        } else if count == 4 {
            contentLeftStackView.addArrangedSubview(imageViews[0])
            contentRightStackView.addArrangedSubview(imageViews[1])
            contentLeftStackView.addArrangedSubview(imageViews[2])
            contentRightStackView.addArrangedSubview(imageViews[3])
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .rightToLeft:
                imageViews[0].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[1].layer.maskedCorners = [.layerMinXMinYCorner]
                imageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]
                imageViews[3].layer.maskedCorners = [.layerMinXMaxYCorner]
            default:
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner]
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[2].layer.maskedCorners = [.layerMinXMaxYCorner]
                imageViews[3].layer.maskedCorners = [.layerMaxXMaxYCorner]
            }
        }
        
        addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            contentWarningOverlayView.topAnchor.constraint(equalTo: container.topAnchor),
            contentWarningOverlayView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentWarningOverlayView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        return imageViews
    }
    
}

extension MosaicImageViewContainer {
    
    @objc private func visualEffectViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mosaicImageViewContainer(self, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
    
    @objc private func photoTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }
        guard let index = imageViews.firstIndex(of: imageView) else { return }
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: tap photo at index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)
        delegate?.mosaicImageViewContainer(self, didTapImageView: imageView, atIndex: index)
    }
    
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct MosaicImageView_Previews: PreviewProvider {
    
    static var images: [UIImage] {
        return ["bradley-dunn", "mrdongok", "lucas-ludwig", "markus-spiske"]
            .map { UIImage(named: $0)! }
    }
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let image = images[3]
                let imageView = view.setupImageView(
                    aspectRatio: image.size,
                    maxSize: CGSize(width: 375, height: 400)
                )
                imageView.image = image
                return view
            }
            .previewLayout(.fixed(width: 375, height: 400))
            .previewDisplayName("Portrait - one image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let image = images[1]
                let imageView = view.setupImageView(
                    aspectRatio: image.size,
                    maxSize: CGSize(width: 375, height: 400)
                )
                imageView.layer.masksToBounds = true
                imageView.layer.cornerRadius = 8
                imageView.contentMode = .scaleAspectFill
                imageView.image = image
                return view
            }
            .previewLayout(.fixed(width: 375, height: 400))
            .previewDisplayName("Landscape - one image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(2)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("two image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(3)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("three image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(4)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("four image")
        }
    }
    
}
#endif
