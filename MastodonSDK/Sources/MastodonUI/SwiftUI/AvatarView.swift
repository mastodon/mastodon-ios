// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import SDWebImageSwiftUI

public struct AvatarSize {
    public static var extraExtraLarge: CGFloat = 106
    public static var extraLarge: CGFloat = 80
    public static var large: CGFloat = 44
    public static var small: CGFloat = 32
    public static var extraSmall: CGFloat = 24
    public static var tiny: CGFloat = 16
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
    var sizeExtraExtraLarge = AvatarSize.extraExtraLarge
    var sizeExtraLarge = AvatarSize.extraLarge
    var sizeLarge = AvatarSize.large
    var sizeSmall = AvatarSize.small
    var sizeExtraSmall = AvatarSize.extraSmall
    var sizeTiny = AvatarSize.tiny
    
    @State var isNavigating: Bool = false
    @Environment(\.displayScale) var displayScale
    
    public enum AvatarStyle {
        case roundedRect
        case circular
    }
    
    public enum Size {
        case extraExtraLarge
        case extraLarge
        case large
        case small
        case extraSmall
        case tiny
        
        public var shape: RoundedRectangle {
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
    let size: Size
    let borderStyle: BorderStyle?
    let avatarSource: AvatarSource?
    let goToProfile: (() async throws -> ())?
    
    public init(style: AvatarStyle, size: Size, borderStyle: BorderStyle? = nil, avatarSource: AvatarSource?, goToProfile: (() async throws -> ())?) {
        self.avatarStyle = style
        self.size = size
        self.borderStyle = borderStyle
        self.avatarSource = avatarSource
        self.goToProfile = goToProfile
    }
    
    private var viewDimension: CGFloat {
        switch size {
        case .extraExtraLarge: sizeExtraExtraLarge
        case .extraLarge: sizeExtraLarge
        case .large: sizeLarge
        case .small: sizeSmall
        case .extraSmall: sizeExtraSmall
        case .tiny: sizeTiny
        }
    }
    
    var avatarShape: AnyShape {
        switch avatarStyle {
        case .roundedRect:
            return AnyShape(size.shape)
        case .circular:
                return AnyShape(Circle())
        }
    }
    
    public var body: some View {
        ZStack {
            avatarImageOrPlaceholder
                .background() {
                    // in case the avatar has an alpha channel
                    switch avatarStyle {
                    case .roundedRect:
                        background(size.shape)
                    case .circular:
                        background(Circle())
                    }
                }
                .overlay {
                    switch avatarStyle {
                    case .roundedRect:
                        overlay(size.shape)
                    case .circular:
                        overlay(Circle())
                    }
                  
                }
            
            if isNavigating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 30)
            }
        }
        .frame(width: viewDimension, height: viewDimension)
        .onTapGesture {
            if let goToProfile, !isNavigating {
                Task {
                    do {
                        isNavigating = true
                        try await goToProfile()
                    } catch {
                    }
                    isNavigating = false
                }
            }
        }
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
                                placeholder(size.shape)
                            case .circular:
                                placeholder(Circle())
                            }
                        }
                    )
                  
                } else {
                    switch avatarStyle {
                    case .roundedRect:
                        placeholder(size.shape)
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

