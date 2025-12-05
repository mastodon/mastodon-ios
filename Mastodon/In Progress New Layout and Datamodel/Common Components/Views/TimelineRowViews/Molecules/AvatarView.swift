// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import SDWebImageSwiftUI

struct AvatarView: View {
    var sizeExtraLarge = AvatarSize.extraLarge
    var sizeLarge = AvatarSize.large
    var sizeSmall = AvatarSize.small
    var sizeTiny = AvatarSize.tiny
    
    @State var isNavigating: Bool = false
    
    enum Size {
        case extraLarge
        case large
        case small
        case tiny
        
        var shape: RoundedRectangle {
            switch self {
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
    
    let size: Size
    let authorAvatarUrl: URL?
    let goToProfile: (() async throws -> ())?
    
    private var viewDimension: CGFloat {
        switch size {
        case .extraLarge: sizeExtraLarge
        case .large: sizeLarge
        case .small: sizeSmall
        case .tiny: sizeTiny
        }
    }
    
    var avatarShape: RoundedRectangle {
        size.shape
    }
    
    var body: some View {
        ZStack {
            if let authorAvatarUrl {
                WebImage(
                    url: authorAvatarUrl,
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
