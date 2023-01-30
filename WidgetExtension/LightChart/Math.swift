//
//  Math.swift
//  
//
//  Created by Alexey Pichukov on 19.08.2020.
//

import Foundation
import CoreGraphics

struct Math {
    
    static func norm(_ vector: [Double]) -> [Double] {
        let norm = sqrt(Double(vector.reduce(0) { $0 + $1 * $1 }))
        return norm == 0 ? vector : vector.map { $0 / norm }
    }

    static func stretchOut(_ vector: [Double]) -> [Double] {
        guard let min = vector.min(),
              let rawMax = vector.max() else {
            return vector
        }
        let max = rawMax - min
        return vector.map { ($0 - min) / (max != 0 ? max : 1) }
    }

    static func stretchIn(_ vector: [Double], offset: Double) -> [Double] {
        guard let max = vector.max() else {
            return vector
        }
        let newMax = max - offset
        return vector.map { $0 * newMax + offset }
    }
}
