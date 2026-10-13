// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct GlassEffectIfAvailable: ViewModifier {
    
    enum BridgingGlass {
        case regular(interactive: Bool)
        case clear(interactive: Bool)
        case identity(interactive: Bool)
        
        @available(iOS 26.0, *)
        var glass: Glass {
            switch self {
            case .regular(let interactive):
                    .regular.interactive(interactive)
            case .clear(let interactive):
                    .clear.interactive(interactive)
            case .identity(let interactive):
                    .identity.interactive(interactive)
            }
        }
    }
    
    let shape: any Shape
    let glass: BridgingGlass
    var tint: Color? = nil
   
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glass.glass.tint(tint), in: shape)
        } else if let tint {
            content
                .background(tint, in: AnyShape(shape))
        } else {
            content
        }
    }
}

extension View {
    func glassEffectIfAvailable(_ glass: GlassEffectIfAvailable.BridgingGlass, withTint tint: Color? = nil, in shape: any Shape) -> some View {
        modifier (
            GlassEffectIfAvailable(shape: shape, glass: glass, tint: tint)
        )
    }
}

struct GlassButtonStyleIfAvailable: ViewModifier {
    let prominent: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                content
                    .buttonStyle(.glassProminent)
            } else {
                content
                    .buttonStyle(.glass)
            }
        } else {
            content
                .buttonStyle(.borderedProminent)
        }
    }
}

extension View {
    func glassButtonStyleIfAvailable(prominent: Bool) -> some View {
        modifier (
            GlassButtonStyleIfAvailable(prominent: prominent)
        )
    }
}

struct TintedBlurBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
    }
}

extension View {
    func tintedBlurBackground() -> some View {
        modifier (
            TintedBlurBackground()
        )
    }
}

struct SharedBackgroundVisibilityHidden<WrappedContent: ToolbarContent>: ToolbarContent {
    let content: WrappedContent
    
    @ToolbarContentBuilder
    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            content
                .sharedBackgroundVisibility(.hidden)
        } else {
            content
        }
    }
}

extension ToolbarContent {
    func sharedBackgroundVisibilityHidden() -> some ToolbarContent {
        SharedBackgroundVisibilityHidden(content: self)
    }
}
