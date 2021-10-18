//
//  LineChartView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-18.
//

import UIKit
import Accelerate
import simd

final class LineChartView: UIView {
    
    var data: [CGFloat] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    let lineShapeLayer = CAShapeLayer()
    let gradientLayer = CAGradientLayer()
    let dotShapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension LineChartView {
    private func _init() {
        lineShapeLayer.frame = bounds
        gradientLayer.frame = bounds
        dotShapeLayer.frame = bounds
        layer.addSublayer(lineShapeLayer)
        layer.addSublayer(gradientLayer)
        layer.addSublayer(dotShapeLayer)
        
        gradientLayer.colors = [
            Asset.Colors.brandBlue.color.withAlphaComponent(0.5).cgColor,
            Asset.Colors.brandBlue.color.withAlphaComponent(0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        lineShapeLayer.frame = bounds
        gradientLayer.frame = bounds
        dotShapeLayer.frame = bounds
        
        guard data.count > 1 else {
            lineShapeLayer.path = nil
            dotShapeLayer.path = nil
            gradientLayer.isHidden = true
            return
        }
        gradientLayer.isHidden = false
        
        // Draw smooth chart
        // use vDSP scale the data with line interpolation method
        var data = data.map { Float($0) }
        // duplicate first and last value to prevent interpolation at edge data
        data.insert(data[0], at: 0)
        if let last = data.last {
            data.append(last)
        }
        
        let n = vDSP_Length(128)
        let stride = vDSP_Stride(1)
        
        // generate fine control with smoothing (simd_smoothstep(_:_:_:))
        let denominator = Float(n) / Float(data.count - 1)
        let control: [Float] = (0...n).map {
            let x = Float($0) / denominator
            return floor(x) + simd_smoothstep(0, 1, simd_fract(x))
        }
        
        var points = [Float](repeating: 0, count: Int(n))
        vDSP_vlint(data,
                   control, stride,
                   &points, stride,
                   n,
                   vDSP_Length(data.count))
        
        guard let maxDataPoint = data.max() else {
            return
        }
        func calculateY(for point: Float, in frame: CGRect) -> CGFloat {
            guard maxDataPoint > 0 else { return .zero }
            return (1 - CGFloat(point / maxDataPoint)) * frame.height
        }
        
        let segmentCount = points.count - 1
        let segmentWidth = bounds.width / CGFloat(segmentCount)
        
        let linePath = UIBezierPath()
        let dotPath = UIBezierPath()
        
        // move to first data point
        var x: CGFloat = 0
        let y = calculateY(for: points[0], in: bounds)
        linePath.move(to: CGPoint(x: x, y: y))
        for point in points.dropFirst() {
            x += segmentWidth
            linePath.addLine(to: CGPoint(
                x: x,
                y: calculateY(for: point, in: bounds)
            ))
        }
        
        if let last = points.last {
            let y = calculateY(for: last, in: bounds)
            let center = CGPoint(x: bounds.maxX, y: y)
            dotPath.addArc(withCenter: center, radius: 3, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        // this not works
        // linePath.lineJoinStyle = .round
        // lineShapeLayer.lineJoin = .round
        
        lineShapeLayer.lineWidth = 3
        lineShapeLayer.strokeColor = Asset.Colors.brandBlue.color.cgColor
        lineShapeLayer.fillColor = UIColor.clear.cgColor
        lineShapeLayer.lineCap = .round
        lineShapeLayer.path = linePath.cgPath
        
        let maskPath = UIBezierPath(cgPath: linePath.cgPath)
        maskPath.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        maskPath.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        maskPath.close()
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillColor = UIColor.red.cgColor
        maskLayer.strokeColor = UIColor.clear.cgColor
        maskLayer.lineWidth = 0.0
        gradientLayer.mask = maskLayer
        
        dotShapeLayer.lineWidth = 3
        dotShapeLayer.fillColor = Asset.Colors.brandBlue.color.cgColor
        dotShapeLayer.path = dotPath.cgPath
    }
}
