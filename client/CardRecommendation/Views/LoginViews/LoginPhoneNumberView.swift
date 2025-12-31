import SwiftUI

struct LoginPhoneNumberView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber: String = ""
    @State private var navigateToEnterOTP = false
    @State var textFieldFocused: Bool = false

    var isDisabled: Bool {
        phoneNumber.filter { $0.isNumber }.count < 10
    }

    var body: some View {
        VStack(spacing: 24) {

            // Title & subtitle
            VStack(spacing: 8) {
                Text("Enter your phone number")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("We'll send you a six-digit code. It expires 5 minutes after you request it.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            // Phone field
            CustomTextField(
                placeholder: "(615) 975-4270",
                text: $phoneNumber,
                keyboardType: .phonePad,
                textAlignment: .center,
                formatter: formatPhoneNumber,
                isFocused: $textFieldFocused
            )

            Spacer()

            // Continue button
            Button(action: {
                Task {
                        if await authManager.sendPhoneCode(phoneNumber: phoneNumber, isRegister: false) {
                            navigateToEnterOTP = true
                        }
                }
            }) {
                HStack { 
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isDisabled ? Color(.systemGray5) : .blue)
                .cornerRadius(30)
            }
            .hapticTap()
            .disabled(isDisabled || authManager.isLoading)
            .padding(.horizontal)
            .padding(.bottom)  // Adjust button position based on keyboard height

        }
        .padding(.top)
        .onAppear {
            // Set focus to the text field when the view appears
            textFieldFocused = true
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
        }
        .navigationDestination(isPresented: $navigateToEnterOTP) {
            LoginOTPVerificationView(phoneNumber: phoneNumber)
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    LoginPhoneNumberView()
}
