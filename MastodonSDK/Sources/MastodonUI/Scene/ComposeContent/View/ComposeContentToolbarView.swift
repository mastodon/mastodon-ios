//
//  ComposeContentToolbarView.swift
//  
//
//  Created by MainasuK on 22/10/18.
//

import SwiftUI
import MastodonAsset

struct ComposeContentToolbarView: View {
    
    static var toolbarHeight: CGFloat { 48 }
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        HStack(spacing: .zero) {
            ForEach(ComposeContentToolbarView.ViewModel.Action.allCases, id: \.self) { action in
                switch action {
                case .attachment:
                    Menu {
                        Button {
                            
                        } label: {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                        }
                        Button {
                            
                        } label: {
                            Label("Camera", systemImage: "camera")
                        }
                        Button {
                            
                        } label: {
                            Label("Browse", systemImage: "ellipsis")
                        }
                    } label: {
                        label(for: action)
                    }
                    .frame(width: 48, height: 48)
                case .visibility:
                    Menu {
                        Picker(selection: $viewModel.visibility) {
                            ForEach(viewModel.allVisibilities, id: \.self) { visibility in
                                Label(visibility.rawValue, systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            Text("Select Visibility")
                        }
                    } label: {
                        label(for: action)
                    }
                    .frame(width: 48, height: 48)
                default:
                    Button {
                        
                    } label: {
                        label(for: action)
                    }
                    .frame(width: 48, height: 48)
                }
            }
            Spacer()
            Text("Hello")
        }
        .padding(.leading, 4)       // 4 + 12 = 16
        .padding(.trailing, 16)
        .frame(height: ComposeContentToolbarView.toolbarHeight)
        .background(Color(viewModel.backgroundColor))
    }
    
}


extension ComposeContentToolbarView {
    func label(for action: ComposeContentToolbarView.ViewModel.Action) -> some View {
        Image(uiImage: action.image.withRenderingMode(.alwaysTemplate))
            .foregroundColor(Color(Asset.Scene.Compose.buttonTint.color))
            .frame(width: 24, height: 24, alignment: .center)
    }
}
