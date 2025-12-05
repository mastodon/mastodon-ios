// Copyright © 2025 Mastodon gGmbH. All rights reserved.
import SwiftUI

struct ReferencePointReader: View {
    static let referenceSpace = "ReferencePointReaderSpace"
    let id: String
    
    let referencePoint: PositionReferencePoint
    
    enum PositionReferencePoint {
        case trailingCenter
        case leadingTop
    }
    
    var body: some View {
        GeometryReader { geo in
            let position =  {
                switch referencePoint {
                case .trailingCenter:
                    CGPoint(
                        x: geo.frame(in: .named(ReferencePointReader.referenceSpace)).maxX,
                        y: geo.frame(in: .named(ReferencePointReader.referenceSpace)).midY
                    )
                case .leadingTop:
                    CGPoint(
                        x: geo.frame(in: .named(ReferencePointReader.referenceSpace)).minX,
                        y: geo.frame(in: .named(ReferencePointReader.referenceSpace)).minY
                    )
                }
               
            }()
            
            Rectangle()
                .fill(Color.clear)
                .preference(
                    key: PositionKey.self,
                    value: [PositionValue(id: id, referencePosition: position)]
                )
        }
    }
}

struct PositionValue: Equatable {
    typealias ID = String
    let id: ID
    let referencePosition: CGPoint
}

struct PositionKey: PreferenceKey {
    static var defaultValue: [PositionValue] = []
    static func reduce(value: inout [PositionValue], nextValue: () -> [PositionValue]) {
        value.append(contentsOf: nextValue())
    }
}

extension Array<PositionValue> {
    func deltaFrom(_ startKey: PositionValue.ID, to endKey: PositionValue.ID) -> CGPoint? {
        var startPoint: CGPoint?
        var endPoint: CGPoint?
        for pref in self {
            if pref.id == startKey {
                startPoint = pref.referencePosition
            } else if pref.id == endKey {
                endPoint = pref.referencePosition
            }
        }
        guard let endPoint, let startPoint else { return nil }
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        return CGPoint(x: deltaX, y: deltaY)
    }
}

struct FrameReader: UIViewRepresentable {
   
    static func frame(ofView uiView: UIView) -> CGRect? {
        guard let window = uiView.window else { return nil }
        let frameInWindow = uiView.convert(uiView.bounds, to: window).integral
        return frameInWindow
    }

    var frameDidUpdate: (CGRect)->()
    
    class Coordinator: NSObject {
        var frameDidUpdate: ((CGRect)->())?
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.frameDidUpdate = frameDidUpdate
        return coordinator
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let frame = FrameReader.frame(ofView: view) {
                context.coordinator.frameDidUpdate?(frame)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let frame = FrameReader.frame(ofView: uiView) {
                context.coordinator.frameDidUpdate?(frame)
            }
        }
    }
}
