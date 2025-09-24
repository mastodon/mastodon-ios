// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import SDWebImageSwiftUI

private let avatarShape = RoundedRectangle(cornerRadius: 8)

struct AvatarView: View {
    var sizeLarge = AvatarSize.large
    var sizeSmall = AvatarSize.small
    var sizeTiny = AvatarSize.tiny
    
    @State var isNavigating: Bool = false
    
    enum Size {
        case large
        case small
        case tiny
        
        var shape: RoundedRectangle {
            switch self {
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
        case .large: sizeLarge
        case .small: sizeSmall
        case .tiny: sizeTiny
        }
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
                            .overlay {
                                avatarShape.stroke(.separator, lineWidth: 0.3)
                            }
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
