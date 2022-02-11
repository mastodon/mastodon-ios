//
//  UIContentSizeCategory.swift
//  UIContentSizeCategory
//
//  Created by Cirno MainasuK on 2021-9-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

extension UIContentSizeCategory {
    // for Dynamic Type
    public static var publisher: AnyPublisher<UIContentSizeCategory, Never> {
        return NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .map { notification in
                let key = UIContentSizeCategory.newValueUserInfoKey
                guard let category = notification.userInfo?[key] as? UIContentSizeCategory else {
                    assertionFailure()
                    return UIApplication.shared.preferredContentSizeCategory
                }
                return category
            }
            .prepend(UIApplication.shared.preferredContentSizeCategory)
            .eraseToAnyPublisher()
    }
}
