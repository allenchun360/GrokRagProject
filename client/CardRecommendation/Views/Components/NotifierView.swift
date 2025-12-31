import SwiftUI

struct NotifierView: View {
    @ObservedObject var notifier = NotificationManager.shared
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        if notifier.isShowing {
            VStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(notifier.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(notifier.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(notifier.backgroundColor)
                .cornerRadius(15)
                .onTapGesture {
                    notifier.onTap?()
                }
                .offset(y: dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height < 0 {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height < -50 {
                                NotificationManager.shared.dismiss()
                            }
                            dragOffset = .zero
                        }
                )

                Spacer()
            }
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
        }
    }
}
