//
//  UIView+Remove.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/4/16.
//

import Foundation
import UIKit

extension UIView {
    func removeFromStackView() {
        if let stackView = self.superview as? UIStackView {
            stackView.removeArrangedSubview(self)
        }
        self.removeFromSuperview()
    }
}
