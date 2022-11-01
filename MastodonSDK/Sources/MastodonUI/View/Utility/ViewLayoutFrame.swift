//
//  ViewLayoutFrame.swift
//  
//
//  Created by MainasuK on 2022-8-17.
//

import os.log
import UIKit
import CoreGraphics

public struct ViewLayoutFrame {
    let logger = Logger(subsystem: "ViewLayoutFrame", category: "ViewLayoutFrame")
    
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
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): layoutFrame update for a view without attached window. Skip this invalid update")
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
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): layoutFrame: \(layoutFrame.debugDescription)")
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): safeAreaLayoutFrame: \(safeAreaLayoutFrame.debugDescription)")
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): readableContentLayoutFrame: \(readableContentLayoutFrame.debugDescription)")

    }
}
