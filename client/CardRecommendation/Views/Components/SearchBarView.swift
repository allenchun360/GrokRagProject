import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: Binding<Bool>? = nil
    @FocusState private var focused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                .focused($focused)
                .textInputAutocapitalization(.words)
                .onAppear {
                    if let isFocused = isFocused {
                        focused = isFocused.wrappedValue
                    }
                }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
