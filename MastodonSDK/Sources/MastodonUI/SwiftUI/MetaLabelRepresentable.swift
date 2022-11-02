//
//  MetaLabelRepresentable.swift
//  
//
//  Created by MainasuK on 22/10/11.
//

import UIKit
import SwiftUI
import MastodonCore
import MetaTextKit

public struct MetaLabelRepresentable: UIViewRepresentable {
    
    public let textStyle: MetaLabel.Style
    public let metaContent: MetaContent
    
    public init(
        textStyle: MetaLabel.Style,
        metaContent: MetaContent
    ) {
        self.textStyle = textStyle
        self.metaContent = metaContent
    }
    
    public func makeUIView(context: Context) -> MetaLabel {
        let view = MetaLabel(style: textStyle)
        view.isUserInteractionEnabled = false
        return view
    }
    
    public func updateUIView(_ view: MetaLabel, context: Context) {
        view.configure(content: metaContent)
    }
    
}

#if DEBUG
struct MetaLabelRepresentable_Preview: PreviewProvider {
    static var previews: some View {
        MetaLabelRepresentable(
            textStyle: .statusUsername,
            metaContent: PlaintextMetaContent(string: "Name")
        )
    }
}
#endif
