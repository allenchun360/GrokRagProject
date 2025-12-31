// CardRecommendation/Views/Components/StoreButtonView.swift
import SwiftUI

struct StoreButtonView: View {
    let store: Store
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Image(systemName: store.logo)
                //     .font(.system(size: 20))
                //     .foregroundColor(.black)

                Text(store.name)
                    .font(.subheadline)
                    .bold()
                    .frame(alignment: .leading)
            }
            .padding()
        }
        .buttonStyle(PressedButtonStyle())
    }
}

struct OnlineStoreButtonView: View {
    let store: OnlineStore
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Image(systemName: store.logo)
                //     .font(.system(size: 20))
                //     .foregroundColor(.black)

                Text(store.name)
                    .font(.subheadline)
                    .bold()
                    .frame(alignment: .leading)
            }
            .padding()
        }
        .buttonStyle(PressedButtonStyle())
    }
}

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? .blue.opacity(0.1) : Color(.systemGray3))
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

//#Preview {
//    StoreButtonView(
//        store: Store(name: "Starbucks", logo: "cup.and.saucer.fill", category: "Coffee"),
//        action: {}
//    )
//    .frame(width: 150)
//    .padding()
//    .background(Color(.systemGray6))
//}
