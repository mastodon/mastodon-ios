// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct ExpandableMediaBadge<Label: View, Content: View>: View {
    @Binding private var isExpanded: Bool
    private let label: Label
    private let content: Content

    @Namespace private var namespace

    init(isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self._isExpanded = isExpanded
        self.content = content()
        self.label = label()
    }

    var body: some View {
        MediaBadge {
            HStack {
                if isExpanded {
                    content
                        .font(.caption)
                        .matchedGeometryEffect(id: "background", in: namespace, properties: .position)
                        .transition(
                            .scale(scale: 0.2, anchor: .bottomLeading)
                            .combined(with: .opacity)
                        )
                    Spacer(minLength: 0)
                } else {
                    label
                        .matchedGeometryEffect(id: "background", in: namespace, properties: .position)
                        .transition(
                            .scale(scale: 3, anchor: .trailing)
                            .combined(with: .opacity)
                        )
                }
            }
            .padding(.vertical, isExpanded ? (8 - 2) : 0)
        }
        .animation(.spring(response: 0.3), value: isExpanded)
        // this is not accessible, but the badge UI is not shown to accessibility tools at the moment
        .onTapGesture {
            isExpanded.toggle()
        }
    }
}

extension ExpandableMediaBadge where Label == Text {
    init(_ label: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.init(isExpanded: isExpanded, content: content) {
            Text(label)
        }
    }
}


struct ExpandableMediaBadge_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableMediaBadge(isExpanded: .constant(false)) {
            Text("Hello world!")
        } label: {
            Text("ALT")
        }
    }
}
