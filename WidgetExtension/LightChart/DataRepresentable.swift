//
//  DataRepresentable.swift
//  
//
//  Created by Alexey Pichukov on 19.08.2020.
//

import Foundation
import CoreGraphics

protocol DataRepresentable {
    func points(forData data: [Double], frame: CGRect, offset: Double, lineWidth: CGFloat) -> [CGPoint]
    func lineWidth(visualType: ChartVisualType) -> CGFloat
}

extension DataRepresentable {
    
    func points(forData data: [Double], frame: CGRect, offset: Double, lineWidth: CGFloat) -> [CGPoint] {
        var vector = Math.stretchOut(Math.norm(data))
        if offset != 0 {
            vector = Math.stretchIn(vector, offset: offset)
        }
        var points: [CGPoint] = []
        for i in 0..<vector.count {
            let x = frame.size.width / CGFloat(vector.count - 1) * CGFloat(i)
            let y = (frame.size.height - lineWidth) * CGFloat(vector[i]) + lineWidth / 2
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
    
    func lineWidth(visualType: ChartVisualType) -> CGFloat {
        switch visualType {
            case .outline(_, let lineWidth):
                return lineWidth
            case .filled(_, let lineWidth):
                return lineWidth
            case .customFilled(_, let lineWidth, _):
                return lineWidth
        }
    }
}
