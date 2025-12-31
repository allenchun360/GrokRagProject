import SwiftUI

enum LandingNavigationType {
    case login
    case register
    case none
}

struct LandingView: View {
    @State private var navigationType: LandingNavigationType = .none
    @State private var navigateToLogin: Bool = false
    @State private var navigateToRegister: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            // Title
            HStack(spacing: 0) {
                Text("Welcome to ")
                    .font(.largeTitle)
                    .fontWeight(.regular)

                Text("AIO")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            Text(
                "AI-powered payments that optimize your rewards, cashback, and discounts in every transaction."
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Spacer()

            // Buttons
            HStack(spacing: 16) {
                Button(action: {
                    navigateToLogin = true
                }) {
                    Text("Log in")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                    .stroke(lineWidth: 2)
                            )
                        // .background(Color.gray.opacity(0.4))
                        .cornerRadius(25)
                }
                .hapticTap()

                Button(action: {
                    navigateToRegister = true
                }) {
                    Text("Sign up")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .hapticTap()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginPhoneNumberView()
        }
        .navigationDestination(isPresented: $navigateToRegister) {
            RegisterPhoneNumberView()
        }
    }
}

#Preview {
    LandingView()
}
