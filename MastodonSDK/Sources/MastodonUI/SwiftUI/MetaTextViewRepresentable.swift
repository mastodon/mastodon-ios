//
//  MetaTextViewRepresentable.swift
//
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import UIKit
import SwiftUI
import UITextView_Placeholder
import MetaTextKit
import MastodonAsset
import MastodonCore

public struct MetaTextViewRepresentable: UIViewRepresentable {

    let metaText = MetaText()
    
    // input
    @Binding var string: String
    let width: CGFloat
    
    // handler
    let configurationHandler: (MetaText) -> Void
    
    public func makeUIView(context: Context) -> MetaTextView {
        let textView = metaText.textView
        
        textView.backgroundColor = .clear                  // clear background
        textView.textContainer.lineFragmentPadding = 0     // remove leading inset
        textView.isScrollEnabled = false                   // enable dynamic height
        
        // set width constraint
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalToConstant: width).priority(.required - 1)
        ])
        // make textView horizontal filled
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // setup editor appearance
        let font = UIFont.preferredFont(forTextStyle: .body)
        metaText.textView.font = font
        metaText.textAttributes = [
            .font: font,
            .foregroundColor: UIColor.label,
        ]
        metaText.linkAttributes = [
            .font: font,
            .foregroundColor: Asset.Colors.brand.color,
        ]
                
        metaText.paragraphStyle = NSMutableParagraphStyle()
        
        configurationHandler(metaText)
            
        metaText.configure(content: PlaintextMetaContent(string: string))
        
        return textView
    }

    public func updateUIView(_ metaTextView: MetaTextView, context: Context) {
        // update layout
        context.coordinator.widthLayoutConstraint.constant = width
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        let view: MetaTextViewRepresentable
        var widthLayoutConstraint: NSLayoutConstraint!

        init(_ view: MetaTextViewRepresentable) {
            self.view = view
            super.init()
            
            widthLayoutConstraint = view.metaText.textView.widthAnchor.constraint(equalToConstant: 100)
            widthLayoutConstraint.isActive = true
        }
    }

}
