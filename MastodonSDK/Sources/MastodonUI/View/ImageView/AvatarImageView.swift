//
//  AvatarImageView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-21.
//

import UIKit
import FLAnimatedImage
import AlamofireImage

public class AvatarImageView: FLAnimatedImageView {
    public var imageViewSize: CGSize?
    public var configuration = Configuration(url: nil)
    public var cornerConfiguration = CornerConfiguration()
}

extension AvatarImageView {
    
    public func prepareForReuse() {
        cancelTask()
        af.cancelImageRequest()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        setup(corner: cornerConfiguration.corner)
    }
    
    private func setup(corner: CornerConfiguration.Corner) {
        layer.masksToBounds = true
        switch corner {
        case .circle:
            layer.cornerCurve = .circular
            layer.cornerRadius = frame.width / 2
        case .fixed(let radius):
            layer.cornerCurve = .continuous
            layer.cornerRadius = radius
        case .scale(let ratio):
            let radius = CGFloat(Int(bounds.width) / ratio)  // even number from quoter of width
            layer.cornerCurve = .continuous
            layer.cornerRadius = radius
        }
    }
    
    private func setup(border: CornerConfiguration.Border?) {
        layer.borderColor = border?.color.cgColor
        layer.borderWidth = border?.width ?? .zero
    }
    
}

extension AvatarImageView {
    
    public static let placeholder = UIImage.placeholder(color: .systemFill)
    
    public struct Configuration {
        public let url: URL?

        public init(
            url: URL?
        ) {
            self.url = url
        }
        
        public init(
            image: UIImage
        ) {
            self.url = nil
        }
    }
    
    public func configure(configuration: Configuration) {
        prepareForReuse()
        
        self.configuration = configuration
        
        guard let url = configuration.url else {
            return
        }
        
        switch url.pathExtension.lowercased() {
        case "gif":
            setImage(
                url: configuration.url,
                scaleToSize: imageViewSize
            )
        default:
            let filter: ImageFilter? = {
                if let imageViewSize = self.imageViewSize {
                    return ScaledToSizeFilter(size: imageViewSize)
                }
                guard self.frame.size.width != 0,
                      self.frame.size.height != 0
                else { return nil }
                return ScaledToSizeFilter(size: self.frame.size)
            }()
            
            af.setImage(
                withURL: url,
                filter: filter
            )
        }
    }
    
}

extension AvatarImageView {
    public struct CornerConfiguration {
        public let corner: Corner
        public let border: Border?

        public init(
            corner: Corner = .circle,
            border: Border? = nil
        ) {
            self.corner = corner
            self.border = border
        }
        
        public enum Corner {
            case circle
            case fixed(radius: CGFloat)
            case scale(ratio: Int = 4)      //  width / ratio
        }
        
        public struct Border {
            public let color: UIColor
            public let width: CGFloat
        }
    }
    
    public func configure(cornerConfiguration: CornerConfiguration) {
        self.cornerConfiguration = cornerConfiguration
        setup(corner: cornerConfiguration.corner)
        setup(border: cornerConfiguration.border)
    }
}
