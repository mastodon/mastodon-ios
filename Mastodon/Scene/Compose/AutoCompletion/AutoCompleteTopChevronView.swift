//
//  AutoCompleteTopChevronView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-14.
//

import UIKit

final class AutoCompleteTopChevronView: UIView {
    
    static let chevronSize = CGSize(width: 20, height: 12)
    
    var chevronMinX: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    func _init() {
        backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
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
        Asset.Colors.Background.systemBackground.color.setFill()
        bezierPath.fill()
        bezierPath.lineWidth = 0
        bezierPath.stroke()
    }
    
}
