//
//  DeleteBackwardResponseTextView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import UIKit

public protocol DeleteBackwardResponseTextViewDelegate: AnyObject {
    func deleteBackwardResponseTextView(_ textView: DeleteBackwardResponseTextView, textBeforeDelete: String?)
}

public final class DeleteBackwardResponseTextView: UITextView {
    
    public weak var deleteBackwardDelegate: DeleteBackwardResponseTextViewDelegate?

    private var height: CGFloat {
        sizeThatFits(CGSize(width: ceil(frame.size.width), height: .greatestFiniteMagnitude)).height
    }

    public override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    public override func deleteBackward() {
        let text = self.text
        super.deleteBackward()
        deleteBackwardDelegate?.deleteBackwardResponseTextView(self, textBeforeDelete: text)
    }

}
