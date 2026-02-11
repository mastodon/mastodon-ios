// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonUI
import SwiftUI

/// This view's body is empty if the altTextBinding is nil.
/// This view expects to dismiss itself by setting the altTextBinding to nil. It does that when the background of the view is tapped or when the view is swiped down to a sufficient offset.
struct AltTextOverlay: View {
    let altTextBinding: Binding<String?>
    @State var offset: CGSize = .zero
    @GestureState var liveOffset: CGSize = .zero
    
    var body: some View {
        if let altText = altTextBinding.wrappedValue {
            GeometryReader { geo in
                ZStack {
                    Color.dimmingBackground
                        .gesture(dismissGesture(forViewHeight: geo.size.height))
                        .onDisappear() {
                            offset = .zero
                        }

                    Text(altText)
                        .foregroundColor(.white)
                        .padding()
                        .background {
                            Color.dimmingBackground
                        }
                        .offset(offset + liveOffset)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    func dismissGesture(forViewHeight viewHeight: CGFloat) -> some Gesture {
        SimultaneousGesture(
            
            TapGesture()
                .onEnded { _ in
                    self.altTextBinding.wrappedValue = nil
                },
            
            DragGesture()
                .updating($liveOffset) { value, state, _ in
                    state = CGSize(width: 0, height: value.translation.height)
                }
                .onEnded { value in
                    if value.translation.height > viewHeight * 0.25 {
                        offset = CGSize(width: 0, height: value.translation.height)
                        withAnimation {
                            offset = CGSize(width: 0, height: viewHeight)
                            altTextBinding.wrappedValue = nil
                        }
                    }
                }
        )
    }
}

/// This button sets the displayAltText.wrappedValue to altText when tapped.  Use the AltTextOverlay to display the text in a dismissable view.
/// The button is hidden from accessibility since accessibility users should have access to the alt text as a description of the media without performing a special action.
struct AltTextButton: View {
    let drawBorder: Bool
    let altText: String
    let displayAltText: Binding<String?>
    
    var body: some View {
        Button {
            displayAltText.wrappedValue = altText
        } label: {
            Text("ALT")
                .foregroundStyle(.white)
                .padding(.vertical, ButtonPadding.vertical)
                .padding(.horizontal, ButtonPadding.horizontal)
                .background() {
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(buttonBackgroundColor)
                        .stroke(drawBorder ? Color.secondary : .clear)
                }
        }
        .fixedSize()
        .padding(standardPadding)
        .buttonStyle(.borderless)
        .accessibilityHidden(true)
    }
}
