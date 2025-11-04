// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI

@MainActor
@Observable class InteractiveLoadingTriggerModel {
    enum TriggerState {
        case progressing(DisplaySpecs)
        case triggered(DisplaySpecs)
        
        var steppedProgress: Double {
            switch self {
            case .progressing(let specs), .triggered(let specs):
                return specs.steppedProgress
            }
        }
        
        var opacity: Double {
            switch self {
            case .progressing(let specs), .triggered(let specs):
                return specs.opacity
            }
        }
        
        var scale: Double {
            switch self {
            case .progressing(let specs), .triggered(let specs):
                return specs.scale
            }
        }
    }
    
    struct DisplaySpecs {
        let steppedProgress: Double
        let opacity: Double
        let scale: Double
        
        static let baseScale: Double = 2
        
        static func defaultSpecs(triggered: Bool) -> Self {
            if triggered {
                .init(steppedProgress: 1, opacity: 1, scale: baseScale)
            } else {
                .init(steppedProgress: 0, opacity: 0, scale: baseScale)
            }
        }
    }
    
    var triggerFrame: CGRect?
    var onTrigger: (()->(Bool))?
    
    var triggerState: TriggerState = .progressing(.defaultSpecs(triggered: false))
    
    func reset(triggered: Bool) {
        if triggered {
            triggerState = .triggered(.defaultSpecs(triggered: true))
            visiblePercent = 1
        } else {
            triggerState = .progressing(.defaultSpecs(triggered: false))
            visiblePercent = 0
        }
    }
    
    fileprivate var visiblePercent: Double = 0 {
        didSet {
            let progress = max(0, min(visiblePercent, 1))
            
            switch triggerState {
            case .progressing:
                let steppedProgress = steppedProgress(progress)
                let opacity = opacity(progress)
                let scale = scale(progress)
                
                let displaySpecs = DisplaySpecs(
                    steppedProgress: steppedProgress,
                    opacity: opacity,
                    scale: scale
                )
                if steppedProgress == 1 {
                    if onTrigger?() == true {
                        triggerState = .triggered(.defaultSpecs(triggered: true))
                    } else {
                        reset(triggered: false)
                    }
                } else {
                    triggerState = .progressing(displaySpecs)
                }
            case .triggered:
                break
            }
        }
    }
    
    var currentState: Double = 0
    
    let totalSteps: Double = 8
    let singleStepPercentage: Double = 0.125
    func steppedProgress(_ progress: Double) -> Double {
        let currentStep = ceil(progress / singleStepPercentage)
        let result = currentStep * singleStepPercentage
        return result
    }
    
    func opacity(_ progress: Double) -> Double {
        // fade in the first step
        if progress < singleStepPercentage {
            return progress / singleStepPercentage
        } else {
            return 1
        }
    }

    func scale(_ progress: Double) -> Double {
        if progress == 1 {
            return DisplaySpecs.baseScale
        }
        
        let progressOfFinalStep = min(0, progress - ((totalSteps - 1) * singleStepPercentage))
        return DisplaySpecs.baseScale + (progressOfFinalStep)
    }
}

extension InteractiveLoadingTriggerModel.TriggerState : CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .progressing(let specs):
            return "SteppedProgress: \(specs.steppedProgress)"
        case .triggered:
            return "TRIGGERED"
        }
    }
}

struct InteractiveLoadingIndicatorRow: View {
   
    @Environment(InteractiveLoadingTriggerModel.self) var triggerModel
    
    var body: some View {
        VStack {
                HStack {
                    Spacer()
                    ZStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(triggerModel.triggerState.scale)
                            .opacity(triggerModel.triggerState.opacity)
                            .mask(
                                PartialPie(startAngle: progressViewMaskStartAngle, percentCovered: triggerModel.triggerState.steppedProgress)
                                    .frame(width: 30, height: 30)
                                    .scaleEffect(triggerModel.triggerState.scale)
                            )
                    }
                    Spacer()
                }
                .padding(EdgeInsets(top: 100, leading: 0, bottom: 100, trailing: 0))
                .background() {
                    GeometryReader { geo in
                        Color.clear
                            .frame(maxHeight: .infinity)
                            .onChange(of: geo.frame(in: .global)) { oldValue, newValue in
                                triggerModel.visiblePercent = visibleRatio(withFrame: newValue)
                            }
                            .onAppear() {
                                triggerModel.visiblePercent = visibleRatio(withFrame: geo.frame(in: .global))
                            }
                    }
                }
        }
    }
    
    let delayPadding: CGFloat = 150
    
    var progressViewMaskStartAngle: Angle {
        Angle(degrees: -90 - (180 / triggerModel.totalSteps)) // start a little before "noon", so that the topmost element of the progress view displays in full)
    }
                                                  
    func visibleRatio(withFrame frame: CGRect) -> Double {
        guard let triggerFrame = triggerModel.triggerFrame else { return 0 }
        let frameHeight = frame.size.height
        let visibleHeight = max(0, (triggerFrame.maxY - delayPadding) - frame.minY)
        if visibleHeight >= frameHeight {
            return 1
        } else {
            let clamped =  min(1, visibleHeight / frameHeight)
            return clamped
        }
    }
}

struct PartialPie: Shape {
    
    var startAngle: Angle
    var percentCovered: Double
    
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        let startAngle = startAngle
        let endAngle = startAngle + Angle.degrees(percentCovered * 360)
       
        var path = Path()
        
        path.move(to: CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        ))
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        path.addLine(to: center)
        path.closeSubpath()
        
        return path
    }
}
