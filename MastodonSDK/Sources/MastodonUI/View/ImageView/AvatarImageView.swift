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
    public var url: URL? = nil
    public var avatarCornerConfiguration = CornerConfiguration()
}

extension AvatarImageView {
    
    public func prepareForReuse() {
        cancelTask() // should cancel any gif loading task
        af.cancelImageRequest() // should cancel any normal image loading task
        self.image = Self.placeholder // because loading a gif doesn't offer a placeholder option and we want to make sure we don't continue showing an avatar from another account while a gif avatar loads
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        setup(corner: avatarCornerConfiguration.corner)
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
    
    public func configure(with url: URL?) {
        prepareForReuse()
        
        self.url = url
        
        guard let url else { return }

        switch url.pathExtension.lowercased() {
        case "gif":
            setImage(
                url: url,
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
                placeholderImage: Self.placeholder,
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
        self.avatarCornerConfiguration = cornerConfiguration
        setup(corner: cornerConfiguration.corner)
        setup(border: cornerConfiguration.border)
    }
}
