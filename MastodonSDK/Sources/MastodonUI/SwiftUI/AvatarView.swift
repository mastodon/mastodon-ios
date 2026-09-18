// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import SDWebImageSwiftUI

public enum AvatarSize: CGFloat {
    case extraExtraLarge = 106
    case extraLarge = 80
    case large = 44
    case small = 32
    case extraSmall = 24
    case tiny = 16
    
    public var roundedRectShape: RoundedRectangle {
        switch self {
        case .extraExtraLarge:
            RoundedRectangle(cornerRadius: CornerRadius.extraExtraLarge)
        case .extraLarge:
            RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
        case .large:
            RoundedRectangle(cornerRadius: CornerRadius.standard)
        case .small:
            RoundedRectangle(cornerRadius: CornerRadius.standard)
        case .extraSmall:
            RoundedRectangle(cornerRadius: CornerRadius.small)
        case .tiny:
            RoundedRectangle(cornerRadius: CornerRadius.tiny)
        }
    }
}

public struct CornerRadius {
    public static var extraExtraLarge: CGFloat = 27
    public static var extraLarge: CGFloat = 8 * 2
    public static var large: CGFloat = 12
    public static var standard: CGFloat = 8
    public static var small: CGFloat = 8 / 2
    public static var tiny: CGFloat = 3
}

public struct AvatarView: View {
    @Environment(\.displayScale) var displayScale
    
    public enum AvatarStyle {
        case roundedRect
        case circular
    }
    
    public enum BorderStyle {
        case backgroundMatching
        case separator
        case both
    }
    
    public enum AvatarSource {
        case url(URL?)
        case local(Image)
    }
    
    let avatarStyle: AvatarStyle
    let size: AvatarSize
    let borderStyle: BorderStyle?
    let avatarSource: AvatarSource?
    
    public init(style: AvatarStyle, size: AvatarSize, borderStyle: BorderStyle? = nil, avatarSource: AvatarSource?) {
        self.avatarStyle = style
        self.size = size
        self.borderStyle = borderStyle
        self.avatarSource = avatarSource
    }
    
    var avatarShape: AnyShape {
        switch avatarStyle {
        case .roundedRect:
            return AnyShape(size.roundedRectShape)
        case .circular:
                return AnyShape(Circle())
        }
    }
    
    public var body: some View {
        avatarImageOrPlaceholder
            .background() {
                // in case the avatar has an alpha channel
                switch avatarStyle {
                case .roundedRect:
                    background(size.roundedRectShape)
                case .circular:
                    background(Circle())
                }
            }
            .overlay {
                switch avatarStyle {
                case .roundedRect:
                    overlay(size.roundedRectShape)
                case .circular:
                    overlay(Circle())
                }
                
            }
            .frame(width: size.rawValue, height: size.rawValue)
    }
    
    @ViewBuilder var avatarImageOrPlaceholder: some View {
        if let avatarSource {
            switch avatarSource {
            case .url(let url):
                if let url {
                    WebImage(
                        url: url,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(avatarShape)
                        },
                        placeholder: {
                            switch avatarStyle {
                            case .roundedRect:
                                placeholder(size.roundedRectShape)
                            case .circular:
                                placeholder(Circle())
                            }
                        }
                    )
                  
                } else {
                    switch avatarStyle {
                    case .roundedRect:
                        placeholder(size.roundedRectShape)
                    case .circular:
                        placeholder(Circle())
                    }
                }
            case .local(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(avatarShape)
            }
        }
    }
    
    @ViewBuilder func background<S: InsettableShape>(_ shape: S) -> some View {
        shape.fill(.background)
    }
    
    @ViewBuilder func overlay<S: InsettableShape>(_ shape: S) -> some View {
        switch borderStyle {
        case .backgroundMatching:
            shape.stroke(.background, lineWidth: 2)
        case .separator:
            shape.stroke(.separator, lineWidth: 1 / displayScale)
        case .both:
            ZStack {
                shape
                    .stroke(.background, lineWidth: 2)
                shape
                    .inset(by: 1)
                    .strokeBorder(.separator, lineWidth: 1 / displayScale)
            }
        case .none:
            switch size {
            case .extraLarge:
                shape.stroke(.background, lineWidth: 2)
            default:
                shape.stroke(.separator, lineWidth: 1 / displayScale)
            }
        }
    }
    
    @ViewBuilder func placeholder<S: InsettableShape>(_ shape: S) -> some View {
        shape
            .foregroundStyle(
                Color(UIColor.secondarySystemFill))
    }
}

