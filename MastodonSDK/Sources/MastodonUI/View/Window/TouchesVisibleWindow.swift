//
//  File.swift
//  
//
//  Created by Chase Carroll on 12/5/22.
//

#if DEBUG

import UIKit

/// View that represents a single touch from the user.
fileprivate final class TouchView: UIView {
    
    private let blurView: UIVisualEffectView
    
    override var frame: CGRect {
        didSet {
            layer.cornerRadius = frame.height / 2.0
        }
    }
    
    override init(frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        blurView = UIVisualEffectView(effect: blurEffect)
        
        super.init(frame: frame)
        
        backgroundColor = .clear
        layer.masksToBounds = true
        layer.cornerCurve = .circular
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2.0
        
        addSubview(blurView)
    }
    
    @available(iOS, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
    }
    
}


/// `UIWindow` subclass that renders visual representations of the user's touches.
public final class TouchesVisibleWindow: UIWindow {
    
    public var touchesVisible = false {
        didSet {
            if !touchesVisible {
                cleanUpAllTouches()
            }
        }
    }
    
    private var touchViews: [UITouch : TouchView] = [:]
    
    private func newTouchView() -> TouchView {
        let touchSize = 44.0
        return TouchView(frame: CGRect(
            origin: .zero,
            size: CGSize(
                width: touchSize,
                height: touchSize
            )
        ))
    }
    
    private func cleanupTouch(_ touch: UITouch) {
        guard let touchView = touchViews[touch] else {
            return
        }
        
        touchView.removeFromSuperview()
        touchViews.removeValue(forKey: touch)
    }
    
    private func cleanUpAllTouches() {
        for (_, touchView) in touchViews {
            touchView.removeFromSuperview()
        }
        
        touchViews.removeAll()
    }
    
    public override func sendEvent(_ event: UIEvent) {
        if touchesVisible {
            let touches = event.allTouches
            
            guard
                let touches = touches,
                touches.count > 0
            else {
                cleanUpAllTouches()
                super.sendEvent(event)
                return
            }
            
            for touch in touches {
                let touchLocation = touch.location(in: self)
                switch touch.phase {
                case .began:
                    let touchView = newTouchView()
                    touchView.center = touchLocation
                    addSubview(touchView)
                    touchViews[touch] = touchView
                    
                case .moved:
                    guard let touchView = touchViews[touch] else {
                        return
                    }
                    touchView.center = touchLocation
                    
                case .ended, .cancelled:
                    cleanupTouch(touch)
                    
                default:
                    break
                }
            }
        }
        
        super.sendEvent(event)
    }
}

#endif
