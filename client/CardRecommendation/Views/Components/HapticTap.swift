import SwiftUI
import UIKit

struct HapticOnTap: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    let generator = UIImpactFeedbackGenerator(style: style)
                    generator.prepare()
                    generator.impactOccurred()
                }
            )
    }
}

extension View {
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.modifier(HapticOnTap(style: style))
    }
}