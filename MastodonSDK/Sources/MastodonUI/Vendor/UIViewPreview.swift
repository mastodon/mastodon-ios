// https://github.com/bielikb/UIViewPreview/blob/master/Sources/UIViewPreview/UIViewPreview.swift

#if canImport(SwiftUI) && DEBUG
import SwiftUI

public struct UIViewPreview<View: UIView>: UIViewRepresentable {
    public let view: View
    public let width: CGFloat?
    public init(width: CGFloat? = nil, _ builder: @escaping () -> View) {
        self.view = builder()
        self.width = width
    }
    // MARK: - UIViewRepresentable
    public func makeUIView(context: Context) -> UIView {
        return view
    }
    public func updateUIView(_ view: UIView, context: Context) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        if let width = width {
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: width),
            ])
        }
    }
}

public struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    public let viewController: ViewController
    
    public init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
    
    // MARK: - UIViewControllerRepresentable
    public func makeUIViewController(context: Context) -> ViewController {
        viewController
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    @available(watchOS, unavailable)
    public func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<UIViewControllerPreview<ViewController>>) {
        return
    }
}
#endif
