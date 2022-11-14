//
//  VisualEffectView.swift
//  
//
//  Created by MainasuK on 2022/11/8.
//

import SwiftUI

// ref: https://stackoverflow.com/a/59111492/3797903
public struct VisualEffectView: UIViewRepresentable {
    public var effect: UIVisualEffect?
    public func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    public func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
