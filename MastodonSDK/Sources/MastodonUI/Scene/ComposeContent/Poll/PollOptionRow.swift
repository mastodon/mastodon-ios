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
    let deleteBackwardResponseTextFieldRelayDelegate: DeleteBackwardResponseTextFieldRelayDelegate?
    let configurationHandler: (DeleteBackwardResponseTextField) -> Void

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: .zero) {
                Image(systemName: "circle")
                    .frame(width: 20, height: 20)
                    .padding(.leading, 16)
                    .padding(.trailing, 16 - 10)     // 8pt for TextField leading
                    .font(.system(size: 17))
                    .accessibilityHidden(true)
                let field = PollOptionTextField(
                    text: $viewModel.text,
                    index: index,
                    delegate: deleteBackwardResponseTextFieldRelayDelegate
                ) { textField in
                    viewModel.textField = textField
                    configurationHandler(textField)
                }
                .onReceive(viewModel.$shouldBecomeFirstResponder) { shouldBecomeFirstResponder in
                    guard shouldBecomeFirstResponder else { return }
                    viewModel.shouldBecomeFirstResponder = false
                    viewModel.textField?.becomeFirstResponder()
                }

                if #available(iOS 16.0, *) {
                    field.accessibilityActions {
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
                        field
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case let (.some(up), .some(down), .none):
                        field
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                    case let (.some(up), .none, .some(remove)):
                        field
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case let (.some(up), .none, .none):
                        field.accessibilityAction(named: L10n.Scene.Compose.Poll.moveUp, up)
                    case let (.none, .some(down), .some(remove)):
                        field
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                            .accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case let (.none, .some(down), .none):
                        field.accessibilityAction(named: L10n.Scene.Compose.Poll.moveDown, down)
                    case let (.none, .none, .some(remove)):
                        field.accessibilityAction(named: L10n.Scene.Compose.Poll.removeOption, remove)
                    case (.none, .none, .none):
                        field
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
