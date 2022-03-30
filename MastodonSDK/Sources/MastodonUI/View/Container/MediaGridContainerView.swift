//
//  MediaGridContainerView.swift
//  MediaGridContainerView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import func AVFoundation.AVMakeRect

public protocol MediaGridContainerViewDelegate: AnyObject {
    func mediaGridContainerView(_ container: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
    func mediaGridContainerView(_ container: MediaGridContainerView, mediaSensitiveButtonDidPressed button: UIButton)
}

public final class MediaGridContainerView: UIView {
    
    static let sensitiveToggleButtonSize = CGSize(width: 34, height: 34)
    public static let maxCount = 9
    
    let logger = Logger(subsystem: "MediaGridContainerView", category: "UI")
    
    public weak var delegate: MediaGridContainerViewDelegate?
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    // lazy var is required here to setup gesture recognizer target-action
    // Swift not doesn't emit compiler error if without `lazy` here
    private(set) lazy var _mediaViews: [MediaView] = {
        var mediaViews: [MediaView] = []
        for i in 0..<MediaGridContainerView.maxCount {
            // init media view
            let mediaView = MediaView()
            mediaView.tag = i
            mediaViews.append(mediaView)
            
            // add gesture recognizer
            let tapGesture = UITapGestureRecognizer.singleTapGestureRecognizer
            tapGesture.addTarget(self, action: #selector(MediaGridContainerView.mediaViewTapGestureRecognizerHandler(_:)))
            mediaView.container.addGestureRecognizer(tapGesture)
            mediaView.container.isUserInteractionEnabled = true
        }
        return mediaViews
    }()
    
    
//    let sensitiveToggleButtonBlurVisualEffectView: UIVisualEffectView = {
//        let visualEffectView = UIVisualEffectView(effect: ContentWarningOverlayView.blurVisualEffect)
//        visualEffectView.layer.masksToBounds = true
//        visualEffectView.layer.cornerRadius = MediaGridContainerView.sensitiveToggleButtonSize.width / 2
//        visualEffectView.layer.cornerCurve = .continuous
//        return visualEffectView
//    }()
//    let sensitiveToggleButtonVibrancyVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: ContentWarningOverlayView.blurVisualEffect))
//    let sensitiveToggleButton: HitTestExpandedButton = {
//        let button = HitTestExpandedButton(type: .system)
//        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
//        button.imageView?.contentMode = .scaleAspectFit
//        button.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
//        return button
//    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    public override var accessibilityElements: [Any]? {
        get {
            mediaViews
        }
        set { }
    }

}

extension MediaGridContainerView {
    private func _init() {
//        sensitiveToggleButton.addTarget(self, action: #selector(MediaGridContainerView.sensitiveToggleButtonDidPressed(_:)), for: .touchUpInside)
    }
}

extension MediaGridContainerView {
    @objc private func mediaViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        guard let index = _mediaViews.firstIndex(where: { $0.container === sender.view }) else { return }
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(index)")
        let mediaView = _mediaViews[index]
        delegate?.mediaGridContainerView(self, didTapMediaView: mediaView, at: index)
    }

    @objc private func sensitiveToggleButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.mediaGridContainerView(self, mediaSensitiveButtonDidPressed: sender)
    }
}

extension MediaGridContainerView {

    public func dequeueMediaView(adaptiveLayout layout: AdaptiveLayout) -> MediaView {
        prepareForReuse()
        
        let mediaView = _mediaViews[0]
        layout.layout(in: self, mediaView: mediaView)
        
//        layoutSensitiveToggleButton()
//        bringSubviewToFront(sensitiveToggleButtonBlurVisualEffectView)
        
        return mediaView
    }
    
    public func dequeueMediaView(gridLayout layout: GridLayout) -> [MediaView] {
        prepareForReuse()
        
        let mediaViews = Array(_mediaViews[0..<layout.count])
        layout.layout(in: self, mediaViews: mediaViews)
        
//        layoutSensitiveToggleButton()
//        bringSubviewToFront(sensitiveToggleButtonBlurVisualEffectView)
        
        return mediaViews
    }
    
    public func prepareForReuse() {
        _mediaViews.forEach { view in
            view.removeFromSuperview()
            view.removeConstraints(view.constraints)
            view.prepareForReuse()
        }
        
        subviews.forEach { view in
            view.removeFromSuperview()
        }
        
        removeConstraints(constraints)
    }

}

extension MediaGridContainerView {
//    private func layoutSensitiveToggleButton() {
//        sensitiveToggleButtonBlurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(sensitiveToggleButtonBlurVisualEffectView)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButtonBlurVisualEffectView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
//            trailingAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.trailingAnchor, constant: 16),
//        ])
//
//        sensitiveToggleButtonVibrancyVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
//        sensitiveToggleButtonBlurVisualEffectView.contentView.addSubview(sensitiveToggleButtonVibrancyVisualEffectView)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButtonVibrancyVisualEffectView.topAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.topAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.leadingAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.leadingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.trailingAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.trailingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.bottomAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.bottomAnchor),
//        ])
//
//        sensitiveToggleButton.translatesAutoresizingMaskIntoConstraints = false
//        sensitiveToggleButtonVibrancyVisualEffectView.contentView.addSubview(sensitiveToggleButton)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButton.topAnchor.constraint(equalTo: sensitiveToggleButtonVibrancyVisualEffectView.contentView.topAnchor),
//            sensitiveToggleButton.leadingAnchor.constraint(equalTo: sensitiveToggleButtonVibrancyVisualEffectView.contentView.leadingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.contentView.trailingAnchor.constraint(equalTo: sensitiveToggleButton.trailingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.contentView.bottomAnchor.constraint(equalTo: sensitiveToggleButton.bottomAnchor),
//            sensitiveToggleButton.widthAnchor.constraint(equalToConstant: MediaGridContainerView.sensitiveToggleButtonSize.width).priority(.required - 1),
//            sensitiveToggleButton.heightAnchor.constraint(equalToConstant: MediaGridContainerView.sensitiveToggleButtonSize.height).priority(.required - 1),
//        ])
//    }
}

extension MediaGridContainerView {
    
    public var mediaViews: [MediaView] {
        _mediaViews.filter { $0.superview != nil }
    }
    
    public func setAlpha(_ alpha: CGFloat) {
        _mediaViews.forEach { $0.alpha = alpha }
    }
    
    public func setAlpha(_ alpha: CGFloat, index: Int) {
        if index < _mediaViews.count {
            _mediaViews[index].alpha = alpha
        }
    }
    
}

extension MediaGridContainerView {
    public struct AdaptiveLayout {
        let aspectRatio: CGSize
        let maxSize: CGSize
        
        func layout(in view: UIView, mediaView: MediaView) {
            let imageViewSize = AVMakeRect(aspectRatio: aspectRatio, insideRect: CGRect(origin: .zero, size: maxSize)).size
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(mediaView)
            NSLayoutConstraint.activate([
                mediaView.topAnchor.constraint(equalTo: view.topAnchor),
                mediaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: view.trailingAnchor).priority(.defaultLow),
                mediaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                mediaView.widthAnchor.constraint(equalToConstant: imageViewSize.width).priority(.required - 1),
                mediaView.heightAnchor.constraint(equalToConstant: imageViewSize.height).priority(.required - 1),
            ])
        }
    }
    
    public struct GridLayout {
        static let spacing: CGFloat = 1
        
        let count: Int
        let maxSize: CGSize
        
        init(count: Int, maxSize: CGSize) {
            self.count = min(count, 9)
            self.maxSize = maxSize
        
        }
        
        private func createStackView(axis: NSLayoutConstraint.Axis) -> UIStackView {
            let stackView = UIStackView()
            stackView.axis = axis
            stackView.semanticContentAttribute = .forceLeftToRight
            stackView.spacing = GridLayout.spacing
            stackView.distribution = .fillEqually
            return stackView
        }
        
        public func layout(in view: UIView, mediaViews: [MediaView]) {
            let containerVerticalStackView = createStackView(axis: .vertical)
            containerVerticalStackView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(containerVerticalStackView)
            NSLayoutConstraint.activate([
                containerVerticalStackView.topAnchor.constraint(equalTo: view.topAnchor),
                containerVerticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerVerticalStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerVerticalStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            
            let count = mediaViews.count
            switch count {
            case 1:
                assertionFailure("should use Adaptive Layout")
                containerVerticalStackView.addArrangedSubview(mediaViews[0])
            case 2:
                let horizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(horizontalStackView)
                horizontalStackView.addArrangedSubview(mediaViews[0])
                horizontalStackView.addArrangedSubview(mediaViews[1])
            case 3:
                let horizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(horizontalStackView)
                horizontalStackView.addArrangedSubview(mediaViews[0])
                
                let verticalStackView = createStackView(axis: .vertical)
                horizontalStackView.addArrangedSubview(verticalStackView)
                verticalStackView.addArrangedSubview(mediaViews[1])
                verticalStackView.addArrangedSubview(mediaViews[2])
            case 4:
                let topHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(topHorizontalStackView)
                topHorizontalStackView.addArrangedSubview(mediaViews[0])
                topHorizontalStackView.addArrangedSubview(mediaViews[1])
                
                let bottomHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(bottomHorizontalStackView)
                bottomHorizontalStackView.addArrangedSubview(mediaViews[2])
                bottomHorizontalStackView.addArrangedSubview(mediaViews[3])
            case 5...9:
                let topHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(topHorizontalStackView)
                topHorizontalStackView.addArrangedSubview(mediaViews[0])
                topHorizontalStackView.addArrangedSubview(mediaViews[1])
                topHorizontalStackView.addArrangedSubview(mediaViews[2])
                
                func mediaViewOrPlaceholderView(at index: Int) -> UIView {
                    return index < mediaViews.count ? mediaViews[index] : UIView()
                }
                let middleHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(middleHorizontalStackView)
                middleHorizontalStackView.addArrangedSubview(mediaViews[3])
                middleHorizontalStackView.addArrangedSubview(mediaViews[4])
                middleHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 5))
                
                if count > 6 {
                    let bottomHorizontalStackView = createStackView(axis: .horizontal)
                    containerVerticalStackView.addArrangedSubview(bottomHorizontalStackView)
                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 6))
                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 7))
                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 8))
                }
            default:
                assertionFailure()
                return
            }
            
            let containerWidth = maxSize.width
            let containerHeight = count > 6 ? containerWidth : containerWidth * 2 / 3
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: containerWidth).priority(.required - 1),
                view.heightAnchor.constraint(equalToConstant: containerHeight).priority(.required - 1),
            ])
        }
    }
}
