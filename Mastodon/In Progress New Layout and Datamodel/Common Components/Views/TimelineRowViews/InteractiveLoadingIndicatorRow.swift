// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore

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
        
        var isTriggered: Bool {
            switch self {
            case .progressing:
                false
            case .triggered:
                true
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
    
    var onTrigger: (()->(Bool))?
    
    var triggerState: TriggerState = .progressing(.defaultSpecs(triggered: false))
    
    func reset(triggered: Bool) {
        if triggered {
            triggerState = .triggered(.defaultSpecs(triggered: true))
            progressTowardsTrigger = 1
        } else {
            triggerState = .progressing(.defaultSpecs(triggered: false))
            progressTowardsTrigger = 0
        }
    }
    
    private(set) var progressTowardsTrigger: Double = 0 {
        didSet {
            let progress = max(0, min(progressTowardsTrigger, 1))
            
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
                        FeedbackGenerator.shared.generate(.impact(.light))
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
    
    func progressTowardsTrigger(withScrollGeometry scrollGeometry: ScrollGeometry) -> Double {
        let pullDistanceToTrigger: CGFloat = 60
        let offsetWhenRestingAtTopOfContent = -scrollGeometry.contentInsets.top
        let offsetWhenRestingAtBottomOfContent = scrollGeometry.contentSize.height + scrollGeometry.contentInsets.bottom - scrollGeometry.containerSize.height
        let restingEndOffset = max(offsetWhenRestingAtTopOfContent /*this will win for content that is shorter than the screen*/, offsetWhenRestingAtBottomOfContent)
        let overscroll = scrollGeometry.contentOffset.y - restingEndOffset
        if overscroll >= pullDistanceToTrigger {
            return 1
        } else if overscroll <= 0 {
            return 0
        } else {
            return floor((overscroll / pullDistanceToTrigger) * 100) / 100
        }
    }
    
    func updateProgressTowardsTrigger(_ newProgress: Double) {
        if newProgress != progressTowardsTrigger {
            progressTowardsTrigger = newProgress
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
        return 1 + DisplaySpecs.baseScale * progress
    }
    
    static let maxScale: CGFloat = DisplaySpecs.baseScale + 1
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
                        .mask(
                            PartialPie(startAngle: progressViewMaskStartAngle, percentCovered: triggerModel.triggerState.isTriggered ? 1.0 : 0.0)
                                .frame(width: 30, height: 30)
                                .scaleEffect(triggerModel.triggerState.scale)
                        )
                    Circle()
                        .stroke(.secondary, lineWidth: 2)
                        .frame(width: 30, height: 30)
                        .scaleEffect(triggerModel.triggerState.scale)
                        .mask(
                            PartialPie(startAngle: progressViewMaskStartAngle, percentCovered: triggerModel.triggerState.isTriggered ? 0.0 : triggerModel.triggerState.steppedProgress)
                                .frame(width: 30, height: 30)
                                .scaleEffect(triggerModel.triggerState.scale)
                        )
                }
                Spacer()
            }
            .padding(EdgeInsets(top: 100, leading: 0, bottom: 100, trailing: 0))
        }
    }
    
    let delayPadding: CGFloat = 150
    
    var progressViewMaskStartAngle: Angle {
        Angle(degrees: -90 - (180 / triggerModel.totalSteps)) // start a little before "noon", so that the topmost element of the progress view displays in full)
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
