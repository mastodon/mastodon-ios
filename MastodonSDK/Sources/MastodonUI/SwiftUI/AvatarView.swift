// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import SDWebImageSwiftUI

public struct AvatarSize {
    public static var extraExtraLarge: CGFloat = 106
    public static var extraLarge: CGFloat = 80
    public static var large: CGFloat = 44
    public static var small: CGFloat = 32
    public static var tiny: CGFloat = 16
}

public struct CornerRadius {
    public static var extraExtraLarge: CGFloat = 27
    public static var extraLarge: CGFloat = 8 * 2
    public static var standard: CGFloat = 8
    public static var small: CGFloat = 8 / 2
    public static var tiny: CGFloat = 3
}

public struct AvatarView: View {
    var sizeExtraExtraLarge = AvatarSize.extraExtraLarge
    var sizeExtraLarge = AvatarSize.extraLarge
    var sizeLarge = AvatarSize.large
    var sizeSmall = AvatarSize.small
    var sizeTiny = AvatarSize.tiny
    
    @State var isNavigating: Bool = false
    @Environment(\.displayScale) var displayScale
    
    public enum Size {
        case extraExtraLarge
        case extraLarge
        case large
        case small
        case tiny
        
        var shape: RoundedRectangle {
            switch self {
            case .extraExtraLarge:
                RoundedRectangle(cornerRadius: CornerRadius.extraExtraLarge)
            case .extraLarge:
                RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
            case .large:
                RoundedRectangle(cornerRadius: CornerRadius.standard)
            case .small:
                RoundedRectangle(cornerRadius: CornerRadius.standard)
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
    
    let size: Size
    let borderStyle: BorderStyle?
    let avatarSource: AvatarSource?
    let goToProfile: (() async throws -> ())?
    
    public init(size: Size, borderStyle: BorderStyle? = nil, avatarSource: AvatarSource?, goToProfile: (() async throws -> ())?) {
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
        case .tiny: sizeTiny
        }
    }
    
    var avatarShape: RoundedRectangle {
        size.shape
    }
    
    public var body: some View {
        ZStack {
            avatarImageOrPlaceholder
                .background() {
                    avatarShape.fill(.background) // in case the avatar has an alpha channel
                }
                .overlay {
                    switch borderStyle {
                    case .backgroundMatching:
                        avatarShape.stroke(.background, lineWidth: 2)
                    case .separator:
                        avatarShape.stroke(.separator, lineWidth: 1 / displayScale)
                    case .both:
                        ZStack {
                            avatarShape
                                .stroke(.background, lineWidth: 2)
                            avatarShape
                                .inset(by: 1)
                                .strokeBorder(.separator, lineWidth: 1 / displayScale)
                        }
                    case .none:
                        switch size {
                        case .extraLarge:
                            avatarShape.stroke(.background, lineWidth: 2)
                        default:
                            avatarShape.stroke(.separator, lineWidth: 1 / displayScale)
                        }
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
                            avatarShape
                                .foregroundStyle(
                                    Color(UIColor.secondarySystemFill))
                        }
                    )
                  
                } else {
                    avatarShape
                        .foregroundStyle(
                            Color(UIColor.secondarySystemFill))
                }
            case .local(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(avatarShape)
            }
        }
    }
}
