// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI

enum AsyncBool {
    case unknown
    case fetching
    case isTrue
    case settingToTrue
    case isFalse
    case settingToFalse
    
    static func fromBool(_ value: Bool?) -> AsyncBool {
        guard let value else { return .unknown }
        if value {
            return .isTrue
        } else {
            return .isFalse
        }
    }
}

struct StatefulCountedActionButton: View {
    struct ActionState {
        let count: Int?
        let isSelected: AsyncBool
    }
    let type: PostAction
    let layoutAxis: Axis
    let showCountLabel: Bool
    let actionState: ActionState
    let doAction: (()->())?
    
    private let iconFont: Font = .body
    
    var body: some View {
        Button(action: { doAction?() }) {
            switch layoutAxis {
            case .horizontal:
                HStack(spacing: 4) {
                    imageComponent
                    countLabelComponent
                }
            case .vertical:
                VStack(spacing: 0) {
                    if showCountLabel {
                        countLabelComponent
                    }
                    ZStack {
                        imageComponent
                            .alignmentGuide(.actionBarAlign) { d in
                                return d[.top]
                            }
                        if !showCountLabel {
                            countLabelComponent
                                .hidden()   // this gives the buttons a standard spacing whether the count labels are being displayed or not
                        }
                    }
                }
            }
        }
        .buttonStyle(.borderless) // Without this, all the buttons in the row activate when one is tapped.  What a remarkably unexpected result with no documentation.
        .fontWeight(actionState.isSelected == .isTrue ? .semibold : .regular)
        .foregroundStyle(color)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder var imageComponent: some View {
        ZStack (alignment: .top) {
            
            if layoutAxis == .vertical {
                // these hidden views make the layout of the buttons consistent for all the different icons
                ProgressView()
                    .progressViewStyle(.circular)
                    .hidden()
                Image(systemName: PostAction.bookmark.systemIconName(filled: true)) // this is the tallest icon
                    .hidden()
            }
            
            // The actual image to display
            switch actionState.isSelected {
            case .isFalse, .isTrue:
                Image(systemName: iconName)
            case .fetching, .settingToFalse, .settingToTrue:
                ProgressView()
                    .progressViewStyle(.circular)
            case .unknown:
                Image(systemName: "questionmark")
            }
        }
        .font(iconFont)
    }
    
    @ViewBuilder var countLabelComponent: some View {
        ZStack(alignment: layoutAxis == .horizontal ? .leading : .center) {
            Text("0000")         // to keep the required space
                .fontWeight(.semibold)
                .hidden()
            Text(countLabel ?? "")
                .contentTransition(.numericText(value: Double(actionState.count ?? 0)))
        }
        .font(.footnote)
    }
    
    private var iconName: String {
        return type.systemIconName(filled: actionState.isSelected == .isTrue)
    }
    private var countLabel: String? {
        guard let count = actionState.count, count > 0 else { return nil }
        return count.formatted(.number.notation(.compactName))
    }
    private var color: Color {
        if actionState.isSelected == .isTrue {
            switch type {
            case .reply: return .secondary
            case .boost: return .green
            case .favourite: return .yellow
            case .bookmark: return .red
            }
        } else {
            return .secondary
        }
    }

}

