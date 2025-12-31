import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isShowing = false
    @Published var title = ""
    @Published var description = ""
    @Published var backgroundColor: Color = .blue
    var onTap: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    private var dismissWorkItem: DispatchWorkItem?  // 👈 track the pending dismiss

    private init() {}

    func show(title: String, description: String, backgroundColor: Color = .blue, duration: Double = 5.0, onTap: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.backgroundColor = backgroundColor
        self.onTap = onTap
        self.onDismiss = onDismiss

        withAnimation {
            isShowing = true
        }

        // cancel previous work item if any
        dismissWorkItem?.cancel()

        // schedule new one
        let workItem = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }

        dismissWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    func dismiss() {
        withAnimation {
            isShowing = false
        }
        dismissWorkItem?.cancel()  // 👈 cancel future dismissal
        onDismiss?()
    }
}
