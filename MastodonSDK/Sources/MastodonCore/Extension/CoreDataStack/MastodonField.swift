//
//  MastodonField.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-9-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonField {
    public convenience init(field: Mastodon.Entity.Field) {
        self.init(
            name: field.name,
            value: field.value,
            verifiedAt: field.verifiedAt
        )
    }
}
