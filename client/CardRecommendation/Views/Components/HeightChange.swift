import SwiftUI

extension View {
    func onHeightChange(_ perform: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        perform(geometry.size.height)
                    }
                    .onChange(of: geometry.size.height) { _, newHeight in
                        perform(newHeight)
                    }
            }
        )
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
