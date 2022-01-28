//
//  MastodonField.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2021-9-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

public final class MastodonField: NSObject, Codable {
    public let name: String
    public let value: String
    public let verifiedAt: Date?
    
    public init(
        name: String,
        value: String,
        verifiedAt: Date?
    ) {
        self.name = name
        self.value = value
        self.verifiedAt = verifiedAt
    }
}
