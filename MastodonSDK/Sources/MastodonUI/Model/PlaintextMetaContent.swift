//
//  PlaintextMetaContent.swift
//  
//
//  Created by MainasuK on 2022-1-10.
//

import Foundation
import Meta

public struct PlaintextMetaContent: MetaContent {
    public let string: String
    public let entities: [Meta.Entity] = []

    public init(string: String) {
        self.string = string
    }

    public func metaAttachment(for entity: Meta.Entity) -> MetaAttachment? {
        return nil
    }
}
