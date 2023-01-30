//
//  File.swift
//  
//
//  Created by Alexey Pichukov on 20.08.2020.
//

import SwiftUI

public struct CurvedChart: View {
    
    private let data: [Double]
    private let frame: CGRect
    private let offset: Double
    private let type: ChartVisualType
    private let currentValueLineType: CurrentValueLineType
    private var points: [CGPoint] = []
    
    /// Creates a new `CurvedChart`
    ///
    /// - Parameters:
    ///     - data: A data set that should be presented on the chart
    ///     - frame: A frame from the parent view
    ///     - visualType: A type of chart, `.outline` by default
    ///     - offset: An offset for the chart, a space below the chart in percentage (0 - 1)
    ///               For example `offset: 0.2` means that the chart will occupy 80% of the upper
    ///               part of the view
    ///     - currentValueLineType: A type of current value line (`none` for no line on chart)
    public init(data: [Double],
                frame: CGRect,
                visualType: ChartVisualType = .outline(color: .red, lineWidth: 2),
                offset: Double = 0,
                currentValueLineType: CurrentValueLineType = .none) {
        self.data = data
        self.frame = frame
        self.type = visualType
        self.offset = offset
        self.currentValueLineType = currentValueLineType
        self.points = points(forData: data,
                             frame: frame,
                             offset: offset,
                             lineWidth: lineWidth(visualType: visualType))
    }
    
    public var body: some View {
        ZStack {
            chart
                .rotationEffect(.degrees(180), anchor: .center)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .drawingGroup()
            line
                .rotationEffect(.degrees(180), anchor: .center)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .drawingGroup()
        }
    }
    
    private var chart: some View {
        switch type {
            case .outline(let color, let lineWidth):
                return AnyView(curvedPath(points: points)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round)))
            case .filled(let color, let lineWidth):
                return AnyView(ZStack {
                    curvedPathGradient(points: points)
                        .fill(LinearGradient(
                            gradient: .init(colors: [color.opacity(0.2), color.opacity(0.02)]),
                            startPoint: .init(x: 0.5, y: 1),
                            endPoint: .init(x: 0.5, y: 0)
                        ))
                    curvedPath(points: points)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                })
            case .customFilled(let color, let lineWidth, let fillGradient):
                return AnyView(ZStack {
                    curvedPathGradient(points: points)
                        .fill(fillGradient)
                    curvedPath(points: points)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                })
        }
    }
    
    private var line: some View {
        switch currentValueLineType {
            case .none:
                return AnyView(EmptyView())
            case .line(let color, let lineWidth):
                return AnyView(
                    currentValueLinePath(points: points)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth))
                )
            case .dash(let color, let lineWidth, let dash):
                return AnyView(
                    currentValueLinePath(points: points)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, dash: dash))
                )
        }
    }

    // MARK: private functions
    
    private func curvedPath(points: [CGPoint]) -> Path {
        func mid(_ point1: CGPoint, _ point2: CGPoint) -> CGPoint {
            return CGPoint(x: (point1.x + point2.x) / 2, y:(point1.y + point2.y) / 2)
        }
        
        func control(_ point1: CGPoint, _ point2: CGPoint) -> CGPoint {
            var controlPoint = mid(point1, point2)
            let delta = abs(point2.y - controlPoint.y)
            
            if point1.y < point2.y {
                controlPoint.y += delta
            } else if point1.y > point2.y {
                controlPoint.y -= delta
            }
            
            return controlPoint
        }
        
        var path = Path()
        guard points.count > 1 else {
            return path
        }
        
        var startPoint = points[0]
        path.move(to: startPoint)
        
        guard points.count > 2 else {
            path.addLine(to: points[1])
            return path
        }
        
        for i in 1..<points.count {
            let currentPoint = points[i]
            let midPoint = mid(startPoint, currentPoint)
            
            path.addQuadCurve(to: midPoint, control: control(midPoint, startPoint))
            path.addQuadCurve(to: currentPoint, control: control(midPoint, currentPoint))
            
            startPoint = currentPoint
        }
        
        return path
    }
    
    private func curvedPathGradient(points: [CGPoint]) -> Path {
        var path = curvedPath(points: points)
        guard let lastPoint = points.last else {
            return path
        }
        path.addLine(to: CGPoint(x: lastPoint.x, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: points[0].y))
        
        return path
    }
    
    private func currentValueLinePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let lastPoint = points.last else {
            return path
        }
        path.move(to: CGPoint(x: 0, y: lastPoint.y))
        path.addLine(to: lastPoint)
        return path
    }
}

extension CurvedChart: DataRepresentable { }
