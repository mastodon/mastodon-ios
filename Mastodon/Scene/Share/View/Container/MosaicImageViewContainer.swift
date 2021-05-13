//
//  MosaicImageViewContainer.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-23.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit

protocol MosaicImageViewContainerPresentable: AnyObject {
    var mosaicImageViewContainer: MosaicImageViewContainer { get }
    var isRevealing: Bool { get }
}

protocol MosaicImageViewContainerDelegate: AnyObject {
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
                imageView.isAccessibilityElement = true
            }
        }
    }
    var blurhashOverlayImageViews: [UIImageView] = []
    
    let contentWarningOverlayView: ContentWarningOverlayView = {
        let contentWarningOverlayView = ContentWarningOverlayView()
        contentWarningOverlayView.configure(style: .visualEffectView)
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
        // accessibility
        accessibilityIgnoresInvertColors = true
        
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
        
        contentWarningOverlayView.delegate = self
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
        contentWarningOverlayView.isUserInteractionEnabled = true
        imageViews = []
        blurhashOverlayImageViews = []
        
        container.spacing = 1
    }
    
    typealias ConfigurableMosaic = (imageView: UIImageView, blurhashOverlayImageView: UIImageView)
    
    func setupImageView(aspectRatio: CGSize, maxSize: CGSize) -> ConfigurableMosaic {
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
        
        let blurhashOverlayImageView = UIImageView()
        blurhashOverlayImageView.layer.masksToBounds = true
        blurhashOverlayImageView.layer.cornerRadius = ContentWarningOverlayView.cornerRadius
        blurhashOverlayImageView.layer.cornerCurve = .continuous
        blurhashOverlayImageView.contentMode = .scaleAspectFill
        blurhashOverlayImageViews.append(blurhashOverlayImageView)
        blurhashOverlayImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(blurhashOverlayImageView)
        NSLayoutConstraint.activate([
            blurhashOverlayImageView.topAnchor.constraint(equalTo: imageView.topAnchor),
            blurhashOverlayImageView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            blurhashOverlayImageView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            blurhashOverlayImageView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
        
        contentWarningOverlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            contentWarningOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            contentWarningOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            contentWarningOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    
        return (imageView, blurhashOverlayImageView)
    }
    
    func setupImageViews(count: Int, maxHeight: CGFloat) -> [ConfigurableMosaic] {
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
        var blurhashOverlayImageViews: [UIImageView] = []
        for _ in 0..<count {
            imageViews.append(UIImageView())
            blurhashOverlayImageViews.append(UIImageView())
        }
        self.imageViews.append(contentsOf: imageViews)
        self.blurhashOverlayImageViews.append(contentsOf: blurhashOverlayImageViews)
        imageViews.forEach { imageView in
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = ContentWarningOverlayView.cornerRadius
            imageView.layer.cornerCurve = .continuous
            imageView.contentMode = .scaleAspectFill
        }
        blurhashOverlayImageViews.forEach { imageView in
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
                
                blurhashOverlayImageViews[1].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                blurhashOverlayImageViews[0].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                
            default:
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                
                blurhashOverlayImageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                blurhashOverlayImageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
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
                
                blurhashOverlayImageViews[0].layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                blurhashOverlayImageViews[1].layer.maskedCorners = [.layerMinXMinYCorner]
                blurhashOverlayImageViews[2].layer.maskedCorners = [.layerMinXMaxYCorner]
            default:
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]
                
                blurhashOverlayImageViews[0].layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                blurhashOverlayImageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                blurhashOverlayImageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]
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
                
                blurhashOverlayImageViews[0].layer.maskedCorners = [.layerMaxXMinYCorner]
                blurhashOverlayImageViews[1].layer.maskedCorners = [.layerMinXMinYCorner]
                blurhashOverlayImageViews[2].layer.maskedCorners = [.layerMaxXMaxYCorner]
                blurhashOverlayImageViews[3].layer.maskedCorners = [.layerMinXMaxYCorner]
            default:
                imageViews[0].layer.maskedCorners = [.layerMinXMinYCorner]
                imageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                imageViews[2].layer.maskedCorners = [.layerMinXMaxYCorner]
                imageViews[3].layer.maskedCorners = [.layerMaxXMaxYCorner]
                
                blurhashOverlayImageViews[0].layer.maskedCorners = [.layerMinXMinYCorner]
                blurhashOverlayImageViews[1].layer.maskedCorners = [.layerMaxXMinYCorner]
                blurhashOverlayImageViews[2].layer.maskedCorners = [.layerMinXMaxYCorner]
                blurhashOverlayImageViews[3].layer.maskedCorners = [.layerMaxXMaxYCorner]
            }
        }
        
        for (imageView, blurhashOverlayImageView) in zip(imageViews, blurhashOverlayImageViews) {
            blurhashOverlayImageView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(blurhashOverlayImageView)
            NSLayoutConstraint.activate([
                blurhashOverlayImageView.topAnchor.constraint(equalTo: imageView.topAnchor),
                blurhashOverlayImageView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                blurhashOverlayImageView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                blurhashOverlayImageView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            ])
        }
        
        contentWarningOverlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            contentWarningOverlayView.topAnchor.constraint(equalTo: container.topAnchor),
            contentWarningOverlayView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentWarningOverlayView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        return zip(imageViews, blurhashOverlayImageViews).map { ($0, $1) }
    }
    
}

// FIXME: refactor blurhash image and preview image
extension MosaicImageViewContainer {

    func setImageViews(alpha: CGFloat) {
        // blurhashOverlayImageViews.forEach { $0.alpha = alpha }
        imageViews.forEach { $0.alpha = alpha }
    }
    
    func setImageView(alpha: CGFloat, index: Int) {
        // if index < blurhashOverlayImageViews.count {
        //     blurhashOverlayImageViews[index].alpha = alpha
        // }
        if index < imageViews.count {
            imageViews[index].alpha = alpha
        }
    }
    
    func thumbnail(at index: Int) -> UIImage? {
        guard blurhashOverlayImageViews.count == imageViews.count else { return nil }
        let tuples = Array(zip(blurhashOverlayImageViews, imageViews))
        guard index < tuples.count else { return nil }
        let tuple = tuples[index]
        return tuple.1.image ?? tuple.0.image
    }
    
    func thumbnails() -> [UIImage?] {
        guard blurhashOverlayImageViews.count == imageViews.count else { return [] }
        let tuples = Array(zip(blurhashOverlayImageViews, imageViews))
        return tuples.map { blurhashOverlayImageView, imageView -> UIImage? in
            return imageView.image ?? blurhashOverlayImageView.image
        }
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
                let (imageView, _) = view.setupImageView(
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
                let (imageView, _) = view.setupImageView(
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
                let mosaics = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, mosiac) in mosaics.enumerated() {
                    let (imageView, blurhashOverlayImageView) = mosiac
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("two image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(3)
                let mosaics = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, mosiac) in mosaics.enumerated() {
                    let (imageView, blurhashOverlayImageView) = mosiac
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("three image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(4)
                let mosaics = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, mosiac) in mosaics.enumerated() {
                    let (imageView, blurhashOverlayImageView) = mosiac
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
