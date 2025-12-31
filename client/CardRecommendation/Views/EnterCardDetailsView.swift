import SwiftUI

enum CardField {
    case name
    case cardNumber
    case expirationDate
    case cvv
}

struct EnterCardDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var cardNumber: String = ""
    @State private var expirationDate: String = ""
    @State private var cvv: String = ""
    @State private var showDatePicker = false
    @State private var navigateToHome = false
    @FocusState private var focusedField: CardField?

    var isDisabled: Bool {
        name.count < 1 || cardNumber.count < 1 || expirationDate.count < 5 || cvv.count < 3
    }

    private func formatCardNumber(_ text: String) -> String {
        let cleanedText = text.replacingOccurrences(of: " ", with: "")
        let formattedText = stride(from: 0, to: cleanedText.count, by: 4).map {
            Array(cleanedText)[$0..<min($0 + 4, cleanedText.count)]
        }.map { String($0) }.joined(separator: " ")

        return formattedText
    }

    private func formatExpirationDate(_ text: String) -> String {
        var cleaned = text.filter { $0.isNumber }
        if cleaned.count > 2 {
            cleaned.insert("/", at: cleaned.index(cleaned.startIndex, offsetBy: 2))
        }
        return cleaned
    }

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 24) {
                // Header text
                VStack(alignment: .center, spacing: 12) {
                    Text("Card Details")
                        .font(.system(size: 32, weight: .bold))

                    Text("Enter your card information.")
                }
                .padding(.top, 20)

                GeometryReader { geometry in
                    VStack {

                        Divider()
                        CardDetailFormRowView(
                            label: "Name",
                            text: $name,
                            placeholder: "Required",
                            keyboardType: .asciiCapable,
                            focusTag: .name,
                            focusedField: _focusedField,
                            width: geometry.size.width
                        )

                        Divider().background(Color.gray)

                        CardDetailFormRowView(
                            label: "Card Number",
                            text: $cardNumber,
                            placeholder: "Required",
                            keyboardType: .numberPad,
                            formatter: formatCardNumber,
                            focusTag: .cardNumber,
                            focusedField: _focusedField,
                            width: geometry.size.width
                        )

                        Divider().background(Color.gray)

                        CardDetailFormRowView(
                            label: "Expiration Date",
                            text: $expirationDate,
                            placeholder: "MM/YY",
                            keyboardType: .numberPad,
                            maxLength: 5,
                            formatter: formatExpirationDate,
                            focusTag: .expirationDate,
                            focusedField: _focusedField,
                            width: geometry.size.width
                        )

                        Divider().background(Color.gray)

                        CardDetailFormRowView(
                            label: "Security Code",
                            text: $cvv,
                            placeholder: "3-digit CVV",
                            keyboardType: .numberPad,
                            maxLength: 3,
                            focusTag: .cvv,
                            focusedField: _focusedField,
                            width: geometry.size.width
                        )
                        Divider()
                    }
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding(.all, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView()
        }
        .onAppear {
            focusedField = .name
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    navigateToHome = true
                }
                .foregroundColor(isDisabled ? .gray: .blue)
                .disabled(isDisabled)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    EnterCardDetailsView()
}
