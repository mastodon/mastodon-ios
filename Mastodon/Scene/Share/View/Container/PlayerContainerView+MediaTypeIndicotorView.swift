//
//  PlayerContainerView+MediaTypeIndicotorView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import UIKit

extension PlayerContainerView {
    
    final class MediaTypeIndicotorView: UIView {
        
        static let indicatorViewSize = CGSize(width: 47, height: 25)
        
        let maskLayer = CAShapeLayer()
        
        let label: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.textAlignment = .right
            label.adjustsFontSizeToFitWidth = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            _init()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            _init()
        }
    
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: bounds.width, y: bounds.height))
            path.addLine(to: CGPoint(x: bounds.width, y: 0))
            path.addLine(to: CGPoint(x: bounds.width * 0.5, y: 0))
            path.addCurve(
                to: CGPoint(x: 0, y: bounds.height),
                controlPoint1: CGPoint(x: bounds.width * 0.2, y: 0),
                controlPoint2: CGPoint(x: 0, y: bounds.height * 0.3)
            )
            path.close()
            
            maskLayer.frame = bounds
            maskLayer.path = path.cgPath
            layer.mask = maskLayer
        }
    }
    
}

extension PlayerContainerView.MediaTypeIndicotorView {
    
    private func _init() {
        backgroundColor = Asset.Colors.Background.mediaTypeIndicotor.color
        layoutMargins = UIEdgeInsets(top: 3, left: 13, bottom: 0, right: 6)
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
    }

    private static func roundedFont(weight: UIFont.Weight,fontSize: CGFloat) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: weight)
        guard let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else { return systemFont }
        let roundedFont = UIFont(descriptor: descriptor, size: fontSize)
        return roundedFont
    }
    
    func setMediaKind(kind: VideoPlayerViewModel.Kind) {
        let fontSize: CGFloat = 18

        switch kind {
        case .gif:
            label.font = PlayerContainerView.MediaTypeIndicotorView.roundedFont(weight: .heavy, fontSize: fontSize)
            label.text = "GIF"
        case .video:
            let configuration = UIImage.SymbolConfiguration(font: PlayerContainerView.MediaTypeIndicotorView.roundedFont(weight: .regular, fontSize: fontSize))
            let image = UIImage(systemName: "video.fill", withConfiguration: configuration)!
            let attachment = NSTextAttachment()
            attachment.image = image.withTintColor(.white)
            label.attributedText = NSAttributedString(attachment: attachment)
        }
    }
    
}
    

