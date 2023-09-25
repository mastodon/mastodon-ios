//
//  ViewLayoutFrame.swift
//  
//
//  Created by MainasuK on 2022-8-17.
//

import UIKit
import CoreGraphics

public struct ViewLayoutFrame {
    public var layoutFrame: CGRect
    public var safeAreaLayoutFrame: CGRect
    public var readableContentLayoutFrame: CGRect
    
    public init(
        layoutFrame: CGRect = .zero,
        safeAreaLayoutFrame: CGRect = .zero,
        readableContentLayoutFrame: CGRect = .zero
    ) {
        self.layoutFrame = layoutFrame
        self.safeAreaLayoutFrame = safeAreaLayoutFrame
        self.readableContentLayoutFrame = readableContentLayoutFrame
    }
}

extension ViewLayoutFrame {
    public mutating func update(view: UIView) {
        guard view.window != nil else {
            return
        }
        
        let layoutFrame = view.frame
        if self.layoutFrame != layoutFrame {
            self.layoutFrame = layoutFrame
        }
        
        let safeAreaLayoutFrame = view.safeAreaLayoutGuide.layoutFrame
        if self.safeAreaLayoutFrame != safeAreaLayoutFrame {
            self.safeAreaLayoutFrame = safeAreaLayoutFrame
        }
        
        let readableContentLayoutFrame = view.readableContentGuide.layoutFrame
        if self.readableContentLayoutFrame != readableContentLayoutFrame {
            self.readableContentLayoutFrame = readableContentLayoutFrame
        }
    }
}
