//
//  AttachmentView.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import SwiftUI

public struct AttachmentView: View {
    
    @ObservedObject public var viewModel: ViewModel
    
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Text("Hi")
    }

}

extension AttachmentView {
    public class ViewModel: ObservableObject {
        
        public init() { }
    }
}
