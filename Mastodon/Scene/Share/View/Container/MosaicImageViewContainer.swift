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
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, didTapContentWarningVisualEffectView visualEffectView: UIVisualEffectView)

}

final class MosaicImageViewContainer: UIView {

    static let cornerRadius: CGFloat = 4
    static let blurVisualEffect = UIBlurEffect(style: .systemUltraThinMaterial)

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
    let blurVisualEffectView = UIVisualEffectView(effect: MosaicImageViewContainer.blurVisualEffect)
    let vibrancyVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: MosaicImageViewContainer.blurVisualEffect))
    let contentWarningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
        label.text = L10n.Common.Controls.Status.mediaContentWarning
        label.textAlignment = .center
        return label
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

extension MosaicImageViewContainer {
    
    private func _init() {
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
        
        // add blur visual effect view in the setup method
        blurVisualEffectView.layer.masksToBounds = true
        blurVisualEffectView.layer.cornerRadius = MosaicImageViewContainer.cornerRadius
        blurVisualEffectView.layer.cornerCurve = .continuous
        
        vibrancyVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurVisualEffectView.contentView.addSubview(vibrancyVisualEffectView)
        NSLayoutConstraint.activate([
            vibrancyVisualEffectView.topAnchor.constraint(equalTo: blurVisualEffectView.topAnchor),
            vibrancyVisualEffectView.leadingAnchor.constraint(equalTo: blurVisualEffectView.leadingAnchor),
            vibrancyVisualEffectView.trailingAnchor.constraint(equalTo: blurVisualEffectView.trailingAnchor),
            vibrancyVisualEffectView.bottomAnchor.constraint(equalTo: blurVisualEffectView.bottomAnchor),
        ])
        
        contentWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        vibrancyVisualEffectView.contentView.addSubview(contentWarningLabel)
        NSLayoutConstraint.activate([
            contentWarningLabel.leadingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.leadingAnchor),
            contentWarningLabel.trailingAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.layoutMarginsGuide.trailingAnchor),
            contentWarningLabel.centerYAnchor.constraint(equalTo: vibrancyVisualEffectView.contentView.centerYAnchor),
        ])
        
        blurVisualEffectView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer.singleTapGestureRecognizer
        tapGesture.addTarget(self, action: #selector(MosaicImageViewContainer.visualEffectViewTapGestureRecognizerHandler(_:)))
        blurVisualEffectView.addGestureRecognizer(tapGesture)
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
        blurVisualEffectView.removeFromSuperview()
        blurVisualEffectView.effect = MosaicImageViewContainer.blurVisualEffect
        vibrancyVisualEffectView.alpha = 1.0
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
        imageView.layer.cornerRadius = MosaicImageViewContainer.cornerRadius
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
        
        blurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurVisualEffectView)
        NSLayoutConstraint.activate([
            blurVisualEffectView.topAnchor.constraint(equalTo: imageView.topAnchor),
            blurVisualEffectView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            blurVisualEffectView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            blurVisualEffectView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
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
            imageView.layer.cornerRadius = MosaicImageViewContainer.cornerRadius
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
        
        blurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurVisualEffectView)
        NSLayoutConstraint.activate([
            blurVisualEffectView.topAnchor.constraint(equalTo: container.topAnchor),
            blurVisualEffectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurVisualEffectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurVisualEffectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        return imageViews
    }
    
}

extension MosaicImageViewContainer {
    
    @objc private func visualEffectViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mosaicImageViewContainer(self, didTapContentWarningVisualEffectView: blurVisualEffectView)
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
                let artworkImageView = view.setupImageView(
                    aspectRatio: image.size,
                    maxSize: CGSize(width: 375, height: 400)
                )
                artworkImageView.image = image
                return view
            }
            .previewLayout(.fixed(width: 375, height: 400))
            .previewDisplayName("Portrait - one image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let image = images[1]
                let artworkImageView = view.setupImageView(
                    aspectRatio: image.size,
                    maxSize: CGSize(width: 375, height: 400)
                )
                artworkImageView.layer.masksToBounds = true
                artworkImageView.layer.cornerRadius = 8
                artworkImageView.contentMode = .scaleAspectFill
                artworkImageView.image = image
                return view
            }
            .previewLayout(.fixed(width: 375, height: 400))
            .previewDisplayName("Landscape - one image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(2)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, artworkImageView) in imageViews.enumerated() {
                    artworkImageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("two image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(3)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, artworkImageView) in imageViews.enumerated() {
                    artworkImageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("three image")
            UIViewPreview(width: 375) {
                let view = MosaicImageViewContainer()
                let images = self.images.prefix(4)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, artworkImageView) in imageViews.enumerated() {
                    artworkImageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("four image")
        }
    }
    
}
#endif
