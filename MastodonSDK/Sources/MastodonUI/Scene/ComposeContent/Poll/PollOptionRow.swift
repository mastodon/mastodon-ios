//
//  PollOptionRow.swift
//  
//
//  Created by MainasuK on 2022-5-31.
//

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization

public struct PollOptionRow: View {
 
    @ObservedObject var viewModel: PollComposeItem.Option
    
    let index: Int
    let moveUp: (() -> Void)?
    let moveDown: (() -> Void)?
    let removeOption: (() -> Void)?
    let deleteBackwardResponseTextViewRelayDelegate: DeleteBackwardResponseTextViewRelayDelegate?
    let configurationHandler: (DeleteBackwardResponseTextView) -> Void

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: .zero) {
                Image(systemName: "circle")
                    .frame(width: 20, height: 20)
                    .padding(.leading, 16)
                    .padding(.trailing, 16 - 10)     // 8pt for TextView leading
                    .font(.system(size: 17))
                    .accessibilityHidden(true)
                let textView = PollOptionEditableTextView(
                    text: $viewModel.text,
                    index: index,
                    delegate: deleteBackwardResponseTextViewRelayDelegate
                ) { textView in
                    viewModel.textView = textView
                    configurationHandler(textView)
                }
                .onReceive(viewModel.$shouldBecomeFirstResponder) { shouldBecomeFirstResponder in
                    guard shouldBecomeFirstResponder else { return }
                    viewModel.shouldBecomeFirstResponder = false
                    viewModel.textView?.becomeFirstResponder()
                }

                if #available(iOS 16.0, *) {
                    textView.accessibilityActions {
                        if let moveUp {
                            Button(L10n.Scene.Compose.Poll.moveUp, action: moveUp)
                        }
                        if let moveDown {
                            Button(L10n.Scene.Compose.Poll.moveDown, action: moveDown)
                        }
                        if let removeOption {
                            Button(L10n.Scene.Compose.Poll.removeOption, action: removeOption)
                        }
                    }
                } else {
                    switch (moveUp, moveDown, removeOption) {
                    case let (.some(up), .some(down), .some(remove)):
                        textView
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case let (.some(up), .some(down), .none):
                        textView
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                    case let (.some(up), .none, .some(remove)):
                        textView
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case let (.some(up), .none, .none):
                        textView.accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                    case let (.none, .some(down), .some(remove)):
                        textView
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case let (.none, .some(down), .none):
                        textView.accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                    case let (.none, .none, .some(remove)):
                        textView.accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case (.none, .none, .none):
                        textView
                    }
                }
            }
            .background(Color(viewModel.backgroundColor))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            Image(uiImage: Asset.Scene.Compose.reorderDot.image.withRenderingMode(.alwaysTemplate))
                .foregroundColor(Color(UIColor.label))
                .accessibilityHidden(true)
        }
        .background(Color.clear)
    }
    
}
