// CardRecommendation/Views/Components/FormRowView.swift
import SwiftUI

struct CardDetailFormRowView: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var maxLength: Int? = nil
    var formatter: ((String) -> String)? = nil
    var focusTag: CardField?
    @FocusState var focusedField: CardField?
    var width: CGFloat

    var body: some View {
        HStack {
            Text(label)
                .bold()
                .padding(.leading, 10)
                .padding(.vertical, 10)
                .frame(width: width * 0.4, alignment: .leading)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(width: width * 0.6)
                .focused($focusedField, equals: focusTag)
                .onChange(of: text) { oldValue, newValue in
                    if let maxLength = maxLength, let formatter = formatter,
                        newValue.count >= maxLength
                    {
                        text = formatter(String(newValue.prefix(maxLength)))
                        focusedField = .cvv
                    } else if let maxLength = maxLength, newValue.count >= maxLength {
                        text = String(newValue.prefix(maxLength))
                    } else if let formatter = formatter {
                        text = formatter(newValue)
                    }
                }
                .onSubmit {
                    switch focusTag {
                    case .name:
                        focusedField = .cardNumber
                    default:
                        break
                    }
                }
        }
    }
}
