//
//  CircleProgressView.swift
//  
//
//  Created by MainasuK on 2022/11/10.
//

import Foundation
import SwiftUI

/// https://stackoverflow.com/a/71467536/3797903
struct CircleProgressView: View {

    let progress: Double
    
    var body: some View {
        let lineWidth: CGFloat = 4
        let tintColor = Color.white
        ZStack {
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .bevel))
                .foregroundColor(tintColor)
                .rotationEffect(Angle(degrees: 270.0))
        }
        .padding(ceil(lineWidth / 2))
    }

}
