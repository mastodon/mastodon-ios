//
//  SawToothView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/17.
//

import Foundation
import UIKit

final class SawToothView: UIView {
    static let widthUint = 8

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    func _init() {
        backgroundColor = Asset.Colors.lightBackground.color
    }

    override func draw(_ rect: CGRect) {
        let bezierPath = UIBezierPath()
        let bottomY = rect.height
        let topY = 0
        let count = Int(ceil(rect.width / CGFloat(SawToothView.widthUint)))
        bezierPath.move(to: CGPoint(x: 0, y: bottomY))
        for n in 0 ..< count {
            bezierPath.addLine(to: CGPoint(x: CGFloat((Double(n) + 0.5) * Double(SawToothView.widthUint)), y: CGFloat(topY)))
            bezierPath.addLine(to: CGPoint(x: CGFloat((Double(n) + 1) * Double(SawToothView.widthUint)), y: CGFloat(bottomY)))
        }
        bezierPath.addLine(to: CGPoint(x: 0, y: bottomY))
        bezierPath.close()
        UIColor.white.setFill()
        bezierPath.fill()
        bezierPath.lineWidth = 0
        bezierPath.stroke()
    }
}
