//
//  PollOptionTextField.swift
//  
//
//  Created by MainasuK on 2022-5-27.
//

import os.log
import UIKit
import SwiftUI
import Combine
import MastodonCore
import MastodonLocalization

public struct PollOptionTextField: UIViewRepresentable {

    let textField = DeleteBackwardResponseTextField()
    
    @Binding var text: String
    
    let index: Int
    let delegate: DeleteBackwardResponseTextFieldRelayDelegate?
    let configurationHandler: (DeleteBackwardResponseTextField) -> Void
    
    public func makeUIView(context: Context) -> DeleteBackwardResponseTextField {
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.textInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.returnKeyType = .next
        textField.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16, weight: .regular))
        textField.adjustsFontForContentSizeCategory = true
        return textField
    }
    
    public func updateUIView(_ textField: DeleteBackwardResponseTextField, context: Context) {
        textField.tag = index
        textField.text = text
        textField.placeholder = {
            if index >= 0 {
                return L10n.Scene.Compose.Poll.optionNumber(index + 1)
            } else {
                assertionFailure()
                return ""
            }
        }()
        textField.delegate = context.coordinator
        textField.deleteBackwardDelegate = context.coordinator
        context.coordinator.delegate = delegate
        configurationHandler(textField)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

protocol DeleteBackwardResponseTextFieldRelayDelegate: AnyObject {
    func deleteBackwardResponseTextFieldDidReturn(_ textField: DeleteBackwardResponseTextField)
    func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?)
}

extension PollOptionTextField {
    public class Coordinator: NSObject {
        let logger = Logger(subsystem: "DeleteBackwardResponseTextFieldRepresentable.Coordinator", category: "Coordinator")
        
        var disposeBag = Set<AnyCancellable>()
        weak var delegate: DeleteBackwardResponseTextFieldRelayDelegate?

        let view: PollOptionTextField
        
        init(_ view: PollOptionTextField) {
            self.view = view
            super.init()
            
            NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: view.textField)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.view.text = view.textField.text ?? ""
                }
                .store(in: &disposeBag)
        }
    }
}

// MARK: - UITextFieldDelegate
extension PollOptionTextField.Coordinator: UITextFieldDelegate {

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let textField = textField as? DeleteBackwardResponseTextField else {
            return true
        }
        delegate?.deleteBackwardResponseTextFieldDidReturn(textField)
        return true
    }
}

extension PollOptionTextField.Coordinator: DeleteBackwardResponseTextFieldDelegate {
    public func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
        delegate?.deleteBackwardResponseTextField(textField, textBeforeDelete: textBeforeDelete)
    }
}
