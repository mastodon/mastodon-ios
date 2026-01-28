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
    let allowScroll: Bool
    
    // input
    let string: Binding<String>
    let width: CGFloat
    
    // handler
    let configurationHandler: (MetaText) -> Void
    
    public init(string: Binding<String>, width: CGFloat, allowScroll: Bool, configurationHandler: @escaping (MetaText) -> Void) {
        self.allowScroll = allowScroll
        self.string = string
        self.width = width
        self.configurationHandler = configurationHandler
    }
    
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
            .foregroundColor: Asset.Colors.Brand.blurple.color,
        ]
                
        metaText.paragraphStyle = NSMutableParagraphStyle()
        
        configurationHandler(metaText)
            
        metaText.configure(content: PlaintextMetaContent(string: string.wrappedValue))
        
        if allowScroll {
            metaText.textView.isScrollEnabled = true
            metaText.textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            metaText.textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        }
        
        return textView
    }

    public func updateUIView(_ metaTextView: MetaTextView, context: Context) {
        
        // update layout
        context.coordinator.widthLayoutConstraint.constant = width
        
        // trigger layout engine update to adjust to text height
        metaText.textView.setNeedsLayout()
        metaText.textView.layoutIfNeeded()
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
