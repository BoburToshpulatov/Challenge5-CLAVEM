import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]
    var onSent: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // ✅ iPad: prevent crash / invisible sheet by providing popover anchor
        if let pop = controller.popoverPresentationController {
            pop.sourceView = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIView()

            pop.sourceRect = CGRect(
                x: pop.sourceView?.bounds.midX ?? 0,
                y: pop.sourceView?.bounds.midY ?? 0,
                width: 0,
                height: 0
            )
            pop.permittedArrowDirections = []
        }

        controller.completionWithItemsHandler = { activityType, completed, _, _ in
            // ✅ Only show toast if user actually completed an action (sent/shared)
            if completed == true {
                onSent?()
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
