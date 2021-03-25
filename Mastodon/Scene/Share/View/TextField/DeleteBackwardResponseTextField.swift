//
//  DeleteBackwardResponseTextField.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import UIKit

protocol DeleteBackwardResponseTextFieldDelegate: class {
    func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?)
}

final class DeleteBackwardResponseTextField: UITextField {
    
    weak var deleteBackwardDelegate: DeleteBackwardResponseTextFieldDelegate?
    
    override func deleteBackward() {
        let text = self.text
        super.deleteBackward()
        deleteBackwardDelegate?.deleteBackwardResponseTextField(self, textBeforeDelete: text)
    }
    
}
