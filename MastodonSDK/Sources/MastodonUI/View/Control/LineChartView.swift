//
//  LineChartView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-18.
//

import UIKit
import Accelerate
import MastodonAsset

public final class LineChartView: UIView {
    
    public var data: [CGFloat] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    let lineShapeLayer = CAShapeLayer()
    let gradientLayer = CAGradientLayer()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension LineChartView {
    private func _init() {
        lineShapeLayer.frame = bounds
        gradientLayer.frame = bounds
        layer.addSublayer(lineShapeLayer)
        layer.addSublayer(gradientLayer)
        
        gradientLayer.colors = [
            Asset.Colors.Primary._300.color.withAlphaComponent(0.5).cgColor,       // set the same alpha to fill
            Asset.Colors.Primary._300.color.withAlphaComponent(0.5).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        lineShapeLayer.frame = bounds
        gradientLayer.frame = bounds
        
        guard data.count > 1 else {
            lineShapeLayer.path = nil
            gradientLayer.isHidden = true
            return
        }
        gradientLayer.isHidden = false
        
        // Draw smooth chart
        guard let maxDataPoint = data.max() else {
            return
        }
        func calculateY(for point: CGFloat, in frame: CGRect) -> CGFloat {
            guard maxDataPoint > 0 else { return .zero }
            return (1 - point / maxDataPoint) * frame.height
        }
        
        let segmentCount = data.count - 1
        let segmentWidth = bounds.width / CGFloat(segmentCount)
        
        let points: [CGPoint] = {
            var points: [CGPoint] = []
            var x: CGFloat = 0
            for value in data {
                let point = CGPoint(x: x, y: calculateY(for: value, in: bounds))
                points.append(point)
                x += segmentWidth
            }
            return points
        }()
        
        guard let linePath = CurveAlgorithm.shared.createCurvedPath(points) else { return }
        let dotPath = UIBezierPath()
        
        if let last = points.last {
            dotPath.addArc(withCenter: last, radius: 3, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }

        lineShapeLayer.lineWidth = 1
        lineShapeLayer.strokeColor = Asset.Colors.Primary._700.color.cgColor
        lineShapeLayer.fillColor = UIColor.clear.cgColor
        lineShapeLayer.lineJoin = .round
        lineShapeLayer.lineCap = .round
        lineShapeLayer.path = linePath.cgPath
        
        let maskPath = UIBezierPath(cgPath: linePath.cgPath)
        maskPath.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        maskPath.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        maskPath.close()
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillColor = Asset.Colors.Brand.blurple.color.cgColor
        maskLayer.strokeColor = UIColor.clear.cgColor
        maskLayer.lineWidth = 0.0
        gradientLayer.mask = maskLayer
    }
}
