// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct GlassEffectIfAvailable: ViewModifier {
    
    //let shape: any Shape
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.clear.interactive())
        } else {
            content
        }
    }
}

extension View {
    func glassEffectIfAvailable() -> some View {
        modifier (
            GlassEffectIfAvailable()
        )
    }
}
