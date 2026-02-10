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
    
    public enum AvatarSource {
        case url(URL?)
        case local(Image)
    }
    
    let size: Size
    let avatarSource: AvatarSource?
    let goToProfile: (() async throws -> ())?
    
    public init(size: Size, avatarSource: AvatarSource?, goToProfile: (() async throws -> ())?) {
        self.size = size
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
                        .overlay {
                            switch size {
                            case .extraLarge:
                                avatarShape.stroke(.background, lineWidth: 2)
                            default:
                                avatarShape.stroke(.separator, lineWidth: 0.3)
                            }
                        }
                    } else {
                        avatarShape
                            .foregroundStyle(
                                Color(UIColor.secondarySystemFill))
                    }
                case .local(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(avatarShape)
                        .overlay {
                            switch size {
                            case .extraLarge:
                                avatarShape.stroke(.background, lineWidth: 2)
                            default:
                                avatarShape.stroke(.separator, lineWidth: 0.3)
                            }
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
}
