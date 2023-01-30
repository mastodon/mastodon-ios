//
//  CGSize.swift
//  
//
//  Created by Jed Fox on 2022-12-20.
//

import Foundation

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
