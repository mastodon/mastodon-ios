//
//  WelcomeIllustrationView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-1.
//

import UIKit

final class WelcomeIllustrationView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension WelcomeIllustrationView {
    private func _init() {
        
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct WelcomeIllustrationView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            WelcomeIllustrationView()
        }
        .previewLayout(.fixed(width: 375, height: 812))
    }
    
}

#endif

