//
//  StripProgressView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import os.log
import UIKit
import Combine

private final class StripProgressLayer: CALayer {
    
    static let progressAnimationKey = "progressAnimationKey"
    static let progressKey = "progress"
    
    var tintColor: UIColor = .black
    @NSManaged var progress: CGFloat

    override class func needsDisplay(forKey key: String) -> Bool {
        switch key {
        case StripProgressLayer.progressKey:
            return true
        default:
            return super.needsDisplay(forKey: key)
        }
    }

    override func display() {
        let progress: CGFloat = {
            guard animation(forKey: StripProgressLayer.progressAnimationKey) != nil else {
                return self.progress
            }
            
            return presentation()?.progress ?? self.progress
        }()
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: progress: %.2f", ((#file as NSString).lastPathComponent), #line, #function, progress)
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            assertionFailure()
            return
        }
        context.clear(bounds)

        var rect = bounds
        let newWidth = CGFloat(progress) * rect.width
        let widthChanged = rect.width - newWidth
        rect.size.width = newWidth
        switch UIApplication.shared.userInterfaceLayoutDirection {
        case .rightToLeft:
            rect.origin.x += widthChanged
        default:
            break
        }
        let path = UIBezierPath(rect: rect)
        context.setFillColor(tintColor.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()

        contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
    }
    
}

final class StripProgressView: UIView {
    
    var disposeBag = Set<AnyCancellable>()
    
    private let stripProgressLayer: StripProgressLayer = {
        let layer = StripProgressLayer()
        return layer
    }()
    
    override var tintColor: UIColor! {
        didSet {
            stripProgressLayer.tintColor = tintColor
            setNeedsDisplay()
        }
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool) {
        stripProgressLayer.removeAnimation(forKey: StripProgressLayer.progressAnimationKey)
        if animated {
            let animation = CABasicAnimation(keyPath: StripProgressLayer.progressKey)
            animation.fromValue = stripProgressLayer.presentation()?.progress ?? stripProgressLayer.progress
            animation.toValue = progress
            animation.duration = 0.33
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.isRemovedOnCompletion = true
            stripProgressLayer.add(animation, forKey: StripProgressLayer.progressAnimationKey)
            stripProgressLayer.progress = progress
        } else {
            stripProgressLayer.progress = progress
            stripProgressLayer.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StripProgressView {
    
    private func _init() {
        layer.addSublayer(stripProgressLayer)
        updateLayerPath()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerPath()
    }
    
}

extension StripProgressView {
    private func updateLayerPath() {
        guard bounds != .zero else { return }
        
        stripProgressLayer.frame = bounds
        stripProgressLayer.tintColor = tintColor
        stripProgressLayer.setNeedsDisplay()
    }
}

#if DEBUG
import SwiftUI

struct VoteProgressStripView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            UIViewPreview() {
                StripProgressView()
            }
            .frame(width: 100, height: 44)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            UIViewPreview() {
                let bar = StripProgressView()
                bar.tintColor = .white
                bar.setProgress(0.5, animated: false)
                return bar
            }
            .frame(width: 100, height: 44)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            UIViewPreview() {
                let bar = StripProgressView()
                bar.tintColor = .white
                bar.setProgress(1.0, animated: false)
                return bar
            }
            .frame(width: 100, height: 44)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
        }
    }

}
#endif
