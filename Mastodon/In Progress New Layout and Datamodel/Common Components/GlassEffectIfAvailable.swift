// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct GlassEffectIfAvailable: ViewModifier {
    
    let shape: any Shape
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.clear.interactive(), in: shape)
        } else {
            content
        }
    }
}

extension View {
    func glassEffectIfAvailable(in shape: any Shape) -> some View {
        modifier (
            GlassEffectIfAvailable(shape: shape)
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
