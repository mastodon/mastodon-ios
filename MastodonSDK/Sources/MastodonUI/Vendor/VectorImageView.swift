//
//  VectorImageView.swift
//  
//
//  Created by MainasuK on 2022-4-29.
//

import UIKit
import SwiftUI

// workaround SwiftUI vector image scale problem
// https://stackoverflow.com/a/61178828/3797903
public struct VectorImageView: UIViewRepresentable {
    
    public var image: UIImage
    public var contentMode: UIView.ContentMode = .scaleAspectFit
    public var tintColor: UIColor = .black
    
    public init(
        image: UIImage,
        contentMode: UIView.ContentMode = .scaleAspectFit,
        tintColor: UIColor = .black
    ) {
        self.image = image
        self.contentMode = contentMode
        self.tintColor = tintColor
    }
    
    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.setContentCompressionResistancePriority(
            .fittingSizeLevel,
            for: .vertical
        )
        return imageView
    }
    
    public func updateUIView(_ imageView: UIImageView, context: Context) {
        imageView.contentMode = contentMode
        imageView.tintColor = tintColor
        imageView.image = image
    }
    
}
