//
//  PlayerContainerView.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/10.
//

import AVKit
import UIKit

protocol PlayerContainerViewDelegate: class {
    func playerContainerView(_ playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
}

final class PlayerContainerView: UIView {
    static let cornerRadius: CGFloat = 8

    private let container = UIView()
    private let touchBlockingView = TouchBlockingView()
    private var containerHeightLayoutConstraint: NSLayoutConstraint!
    
    let contentWarningOverlayView: ContentWarningOverlayView = {
        let contentWarningOverlayView = ContentWarningOverlayView()
        return contentWarningOverlayView
    }()
    
    let playerViewController = AVPlayerViewController()
    
    let mediaTypeIndicotorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let mediaTypeIndicotorView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.mediaTypeIndicotor.color
        view.translatesAutoresizingMaskIntoConstraints = false
        let rect = CGRect(x: 0, y: 0, width: 47, height: 50)
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft], cornerRadii: CGSize(width: 50, height: 50))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
        return view
    }()
    
    weak var delegate: PlayerContainerViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension PlayerContainerView {
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        containerHeightLayoutConstraint = container.heightAnchor.constraint(equalToConstant: 162).priority(.required - 1)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
            containerHeightLayoutConstraint,
        ])
        
        // will not influence full-screen playback
        playerViewController.view.layer.masksToBounds = true
        playerViewController.view.layer.cornerRadius = PlayerContainerView.cornerRadius
        playerViewController.view.layer.cornerCurve = .continuous
        
        addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            contentWarningOverlayView.topAnchor.constraint(equalTo: topAnchor),
            contentWarningOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentWarningOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        contentWarningOverlayView.delegate = self
        
        // mediaType
        addSubview(mediaTypeIndicotorView)
        NSLayoutConstraint.activate([
            mediaTypeIndicotorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mediaTypeIndicotorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mediaTypeIndicotorView.heightAnchor.constraint(equalToConstant: 25),
            mediaTypeIndicotorView.widthAnchor.constraint(equalToConstant: 47)
        ])
        
        mediaTypeIndicotorView.addSubview(mediaTypeIndicotorLabel)
        NSLayoutConstraint.activate([
            mediaTypeIndicotorLabel.topAnchor.constraint(equalTo: mediaTypeIndicotorView.topAnchor),
            mediaTypeIndicotorLabel.leadingAnchor.constraint(equalTo: mediaTypeIndicotorView.leadingAnchor),
            mediaTypeIndicotorLabel.bottomAnchor.constraint(equalTo: mediaTypeIndicotorView.bottomAnchor),
            mediaTypeIndicotorView.trailingAnchor.constraint(equalTo: mediaTypeIndicotorLabel.trailingAnchor, constant: 8)
        ])
    }
}

// MARK: - ContentWarningOverlayViewDelegate
extension PlayerContainerView: ContentWarningOverlayViewDelegate {
    func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.playerContainerView(self, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
}

extension PlayerContainerView {
    func reset() {
        // note: set playerViewController.player pause() and nil in data source configuration process make reloadData not break playing
        
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
        
        container.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
    }
    
    func setupPlayer(aspectRatio: CGSize, maxSize: CGSize, parent: UIViewController?) -> AVPlayerViewController {
        reset()
        
        touchBlockingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(touchBlockingView)
        NSLayoutConstraint.activate([
            touchBlockingView.topAnchor.constraint(equalTo: container.topAnchor),
            touchBlockingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            touchBlockingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        let rect = AVMakeRect(
            aspectRatio: aspectRatio,
            insideRect: CGRect(origin: .zero, size: maxSize)
        )
        
        parent?.addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        touchBlockingView.addSubview(playerViewController.view)
        parent.flatMap { playerViewController.didMove(toParent: $0) }
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: touchBlockingView.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: touchBlockingView.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: touchBlockingView.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: touchBlockingView.bottomAnchor),
            touchBlockingView.widthAnchor.constraint(equalToConstant: floor(rect.width)).priority(.required - 1),
        ])
        containerHeightLayoutConstraint.constant = floor(rect.height)
        containerHeightLayoutConstraint.isActive = true
        
        bringSubviewToFront(mediaTypeIndicotorView)
        
        return playerViewController
    }
    
    func setMediaKind(kind: VideoPlayerViewModel.Kind) {
        switch kind {
        case .gif:
            mediaTypeIndicotorLabel.text = "GIF"
        case .video:
            let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 18, weight: .regular))
            let image = UIImage(systemName: "video.fill", withConfiguration: configuration)!
            let attachment = NSTextAttachment()
            attachment.image = image.withTintColor(.white)
            mediaTypeIndicotorLabel.attributedText = NSAttributedString(attachment: attachment)
        }
    }
}
