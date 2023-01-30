//
//  LineChart.swift
//  
//
//  Created by Alexey Pichukov on 19.08.2020.
//

import SwiftUI

public struct LineChart: View {
    
    private let data: [Double]
    private let frame: CGRect
    private let offset: Double
    private let type: ChartVisualType
    private let currentValueLineType: CurrentValueLineType
    private var points: [CGPoint] = []
    
    /// Creates a new `LineChart`
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
                return AnyView(linePath(points: points)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round)))
            case .filled(let color, let lineWidth):
                return AnyView(ZStack {
                    linePathGradient(points: points)
                        .fill(LinearGradient(
                            gradient: .init(colors: [color.opacity(0.2), color.opacity(0.02)]),
                            startPoint: .init(x: 0.5, y: 1),
                            endPoint: .init(x: 0.5, y: 0)
                        ))
                    linePath(points: points)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                })
            case .customFilled(let color, let lineWidth, let fillGradient):
                return AnyView(ZStack {
                    linePathGradient(points: points)
                        .fill(fillGradient)
                    linePath(points: points)
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
    
    private func linePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else {
            return path
        }
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        return path
    }
    
    private func linePathGradient(points: [CGPoint]) -> Path {
        var path = linePath(points: points)
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

extension LineChart: DataRepresentable { }
