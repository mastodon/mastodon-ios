//
//  VoteProgressStripView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import UIKit
import Combine

final class VoteProgressStripView: UIView {
    
    var disposeBag = Set<AnyCancellable>()
    
    private lazy var stripLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineCap = .round
        shapeLayer.fillColor = tintColor.cgColor
        shapeLayer.strokeColor = UIColor.clear.cgColor
        return shapeLayer
    }()
    
    let progressMaskLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.red.cgColor
        return shapeLayer
    }()

    let progress = CurrentValueSubject<CGFloat, Never>(0.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension VoteProgressStripView {
    
    private func _init() {
        updateLayerPath()
        
        layer.addSublayer(stripLayer)
        
        progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.33) {
                    self.updateLayerPath()
                }
            }
            .store(in: &disposeBag)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerPath()
    }
    
}

extension VoteProgressStripView {
    private func updateLayerPath() {
        guard bounds != .zero else { return }
        
        stripLayer.frame = bounds
        stripLayer.fillColor = tintColor.cgColor
        
        stripLayer.path = {
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: 0)
            return path.cgPath
        }()
        
        
        progressMaskLayer.path = {
            var rect = bounds
            let newWidth = progress.value * rect.width
            let widthChanged = rect.width - newWidth
            rect.size.width = newWidth
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .rightToLeft:
                rect.origin.x += widthChanged
            default:
                break
            }
            let path = UIBezierPath(rect: rect)
            return path.cgPath
        }()
        stripLayer.mask = progressMaskLayer
    }
    
}


#if DEBUG
import SwiftUI

struct VoteProgressStripView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            UIViewPreview() {
                VoteProgressStripView()
            }
            .frame(width: 100, height: 44)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            UIViewPreview() {
                let bar = VoteProgressStripView()
                bar.tintColor = .white
                bar.progress.value = 0.5
                return bar
            }
            .frame(width: 100, height: 44)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            UIViewPreview() {
                let bar = VoteProgressStripView()
                bar.tintColor = .white
                bar.progress.value = 1.0
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
