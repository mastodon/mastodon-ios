// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct ExpandableMediaBadge<Label: View, Content: View>: View {
    @Binding private var isExpanded: Bool
    private let parentGeometry: (size: CGSize, space: AnyHashable)
    private let label: Label
    private let content: Content

    @Namespace private var namespace

    init(isExpanded: Binding<Bool>, in parentGeometry: (CGSize, AnyHashable), @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self._isExpanded = isExpanded
        self.parentGeometry = parentGeometry
        self.content = content()
        self.label = label()
    }

    var body: some View {
        MediaBadge {
            label
        }
        .opacity(0)
        .overlay {
            GeometryReader { geom in
                Color.clear
                    .preference(key: OffsetRect.self, value: geom.frame(in: .named(parentGeometry.space)))
            }
        }
        .overlayPreferenceValue(OffsetRect.self, alignment: .bottomLeading) { offsetRect in
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
                            .layoutPriority(1)
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
            .frame(width: isExpanded ? parentGeometry.size.width : nil)
            .offset(x: isExpanded ? -offsetRect.minX : 0)
            .animation(.spring(response: 0.3), value: isExpanded)
            // this is not accessible, but the badge UI is not shown to accessibility tools at the moment
            .onTapGesture {
                isExpanded.toggle()
            }
        }
        // necessary to keep the expanded state from underlapping the collapsed badges
        // NOTE: if you want multiple expandable badges you will need to change this somehow. Good luck!
        .zIndex(1)
    }
}

extension ExpandableMediaBadge where Label == Text {
    init(_ label: String, isExpanded: Binding<Bool>, in parentGeometry: (CGSize, AnyHashable), @ViewBuilder content: () -> Content) {
        self.init(isExpanded: isExpanded, in: parentGeometry, content: content) {
            Text(label)
        }
    }
}

private struct OffsetRect: PreferenceKey {
    static var defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct ExpandableMediaBadge_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geom in
            ExpandableMediaBadge(isExpanded: .constant(false), in: (geom.size, "preview")) {
                Text("Hello world!")
            } label: {
                Text("ALT")
            }
        }.coordinateSpace(name: "preview")
    }
}
