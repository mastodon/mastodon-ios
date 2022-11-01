//
//  PollOptionRow.swift
//  
//
//  Created by MainasuK on 2022-5-31.
//

import SwiftUI
import MastodonAsset
import MastodonCore

public struct PollOptionRow: View {
 
    @ObservedObject var viewModel: PollComposeItem.Option
    
    let index: Int?
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
                PollOptionTextField(
                    text: $viewModel.text,
                    index: index ?? -1,
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
            }
            .background(Color(viewModel.backgroundColor))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            Image(uiImage: Asset.Scene.Compose.reorderDot.image.withRenderingMode(.alwaysTemplate))
                .foregroundColor(Color(UIColor.label))
        }
        .background(Color.clear)
    }
    
}
