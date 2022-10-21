//
//  PollOptionRow.swift
//  
//
//  Created by MainasuK on 2022-5-31.
//

import SwiftUI
import MastodonCore

public struct PollOptionRow: View {
 
    @ObservedObject var viewModel: PollComposeItem.Option
    
    let index: Int?
    let deleteBackwardResponseTextFieldRelayDelegate: DeleteBackwardResponseTextFieldRelayDelegate?
    let configurationHandler: (DeleteBackwardResponseTextField) -> Void

    public var body: some View {
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
    
}
