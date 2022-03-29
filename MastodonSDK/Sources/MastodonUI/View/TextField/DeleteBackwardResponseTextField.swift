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
    
    public override func deleteBackward() {
        let text = self.text
        super.deleteBackward()
        deleteBackwardDelegate?.deleteBackwardResponseTextField(self, textBeforeDelete: text)
    }
    
}
