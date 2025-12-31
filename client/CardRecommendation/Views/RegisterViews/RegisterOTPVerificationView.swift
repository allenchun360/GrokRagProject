import SwiftUI

struct RegisterOTPVerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var otpCode: String = ""
    @State private var navigateToRegisterName = false
    @FocusState private var textFieldFocused: Bool

    let phoneNumber: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {

            // Title & subtitle
            VStack(spacing: 8) {
                Text("We sent you a text message")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(
                    "Verify your identity by entering the one-time code sent to your phone number."
                )
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .padding(.top, 20)

            // OTP field
            TextField("000000", text: $otpCode)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($textFieldFocused)
                .font(.title2)
                .padding()
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal)
                .onChange(of: otpCode) { oldValue, newValue in
                    if newValue.count >= 6 {
                        otpCode = String(newValue.prefix(6))
                        textFieldFocused = false
                        Task {
                            if await authManager.register(phoneNumber: phoneNumber, code: otpCode) {
                                authManager.registeredName = true
                                navigateToRegisterName = true
                            } else {
                                textFieldFocused = true
                            }
                        }
                    }
                }

            Spacer()

            // Help button
            Button(action: {
                // Handle help action
            }) {
                Text("I need help")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom)  // Adjust button position based on keyboard height

        }
        .padding(.top)
        .onAppear {
            // Set focus to the text field when the view appears
            textFieldFocused = true
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                }
            }
        }
        .navigationDestination(isPresented: $navigateToRegisterName) {
            RegisterNameView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RegisterOTPVerificationView(phoneNumber: "3103872336")
}
