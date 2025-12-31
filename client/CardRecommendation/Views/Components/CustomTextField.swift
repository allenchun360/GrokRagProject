import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textAlignment: TextAlignment = .center
    var formatter: ((String) -> String)? = nil
    var maxLength: Int? = nil
    var isFocused: Binding<Bool>? = nil
    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .multilineTextAlignment(textAlignment)
            .keyboardType(keyboardType)
            .focused($focused)
            .font(.title2)
            .padding()
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal)
            .onChange(of: text) { oldValue, newValue in
                if let maxLength = maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
                if let formatter = formatter {
                    text = formatter(newValue)
                }
            }
            .onAppear {
                if let isFocused = isFocused {
                    focused = isFocused.wrappedValue
                }
            }

    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        // Phone number style
        CustomTextField(
            placeholder: "(615) 975-4270",
            text: .constant(""),
            keyboardType: .phonePad,
            textAlignment: .center
        )

        // OTP style
        CustomTextField(
            placeholder: "000000",
            text: .constant(""),
            keyboardType: .numberPad,
            textAlignment: .center
        )

        // Regular style
        CustomTextField(
            placeholder: "Enter text",
            text: .constant("")
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
