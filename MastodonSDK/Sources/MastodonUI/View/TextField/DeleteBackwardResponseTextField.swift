//
//  DeleteBackwardResponseTextField.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import UIKit

public protocol DeleteBackwardResponseTextFieldDelegate: AnyObject {
    func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?)
}

public final class DeleteBackwardResponseTextField: UITextField {
    
    public weak var deleteBackwardDelegate: DeleteBackwardResponseTextFieldDelegate?
    
    public var textInset: UIEdgeInsets = .zero
    
    public override func deleteBackward() {
        let text = self.text
        super.deleteBackward()
        deleteBackwardDelegate?.deleteBackwardResponseTextField(self, textBeforeDelete: text)
    }
    
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textInset)
    }
    
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textInset)
    }
    
}
