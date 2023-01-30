import SwiftUI

public struct LightChartView: View {
    
    private let data: [Double]
    private let type: ChartType
    private let visualType: ChartVisualType
    private let offset: Double
    private let currentValueLineType: CurrentValueLineType
    
    public init(data: [Double],
                type: ChartType = .line,
                visualType: ChartVisualType = .outline(color: .red, lineWidth: 2),
                offset: Double = 0,
                currentValueLineType: CurrentValueLineType = .none) {
        self.data = data
        self.type = type
        self.visualType = visualType
        self.offset = offset
        self.currentValueLineType = currentValueLineType
    }
    
    public var body: some View {
        GeometryReader { reader in
            chart(withFrame: CGRect(x: 0,
                                    y: 0,
                                    width: reader.frame(in: .local).width ,
                                    height: reader.frame(in: .local).height))
        }
    }
    
    private func chart(withFrame frame: CGRect) -> AnyView {
        switch type {
            case .line:
                return AnyView(
                    LineChart(data: data,
                                         frame: frame,
                                         visualType: visualType,
                                         offset: offset,
                                         currentValueLineType: currentValueLineType)
                )
            case .curved:
                return AnyView(
                    CurvedChart(data: data,
                                           frame: frame,
                                           visualType: visualType,
                                           offset: offset,
                                           currentValueLineType: currentValueLineType)
                )
        }
    }
}
