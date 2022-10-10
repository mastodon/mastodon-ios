//
//  ComposeContentView.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import SwiftUI

public struct ComposeContentView: View {
    
    @ObservedObject var viewModel: ComposeContentViewModel
    
    @State var contentOffsetDelta: CGFloat = .zero
    
    public var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scrollView")).origin
                    )
                }.frame(width: 0, height: 0)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    print("contentOffset: \(offset)")
                }
                VStack {
                    Text("Reply")
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ViewFramePreferenceKey.self,
                            value: geometry.frame(in: .named("scrollView"))
                        )
                    }
                    .onPreferenceChange(ViewFramePreferenceKey.self) { frame in
                        print("reply frame: \(frame)")
                    }
                )
                VStack {
                    Text("Content")
                }
                .frame(maxWidth: .infinity)
                .background(Color.orange)
            }   // end VStack
            .offset(y: contentOffsetDelta)
        }   // end ScrollView
        .coordinateSpace(name: "scrollView")
    }   // end body
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

private struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}

//struct ScrollView<Content: View>: View {
//    let axes: Axis.Set
//    let showsIndicators: Bool
//    let offsetChanged: (CGPoint) -> Void
//    let content: Content
//
//    init(
//        axes: Axis.Set = .vertical,
//        showsIndicators: Bool = true,
//        offsetChanged: @escaping (CGPoint) -> Void = { _ in },
//        @ViewBuilder content: () -> Content
//    ) {
//        self.axes = axes
//        self.showsIndicators = showsIndicators
//        self.offsetChanged = offsetChanged
//        self.content = content()
//    }
//
//    var body: some View {
//        SwiftUI.ScrollView(axes, showsIndicators: showsIndicators) {
//            GeometryReader { geometry in
//                Color.clear.preference(
//                    key: ScrollOffsetPreferenceKey.self,
//                    value: geometry.frame(in: .named("scrollView")).origin
//                )
//            }.frame(width: 0, height: 0)
//            content
//        }
//        .coordinateSpace(name: "scrollView")
//        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: offsetChanged)
//    }
//}
