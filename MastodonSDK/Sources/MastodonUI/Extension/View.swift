//
//  View.swift
//  
//
//  Created by MainasuK on 2022/11/8.
//

import SwiftUI

extension View {
    public func badgeView<Content>(_ content: Content) -> some View where Content: View {
        overlay(
            ZStack {
                content
            }
            .alignmentGuide(.top) { $0.height / 2 }
            .alignmentGuide(.trailing) { $0.width / 2 }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        )
    }
}
