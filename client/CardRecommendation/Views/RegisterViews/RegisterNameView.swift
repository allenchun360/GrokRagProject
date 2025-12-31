import SwiftUI

struct RegisterNameView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var navigateToEnterCreditCard = false
    @FocusState private var focusedField: Field?

    var isDisabled: Bool {
        firstName.count < 1 || lastName.count < 1
    }

    enum Field {
        case firstName
        case lastName
    }

    var body: some View {
        VStack(spacing: 24) {

            // Title & subtitle
            VStack(spacing: 8) {
                Text("What's your legal name?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(
                    "Enter your name as it appears on your government ID so we can confirm your identity."
                )
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .padding(.top, 20)

            // OTP field
            TextField("First Name", text: $firstName)
                .multilineTextAlignment(.center)
                .keyboardType(.asciiCapable)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .firstName)
                .font(.title2)
                .padding()
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal)
                .onSubmit {
                    focusedField = .lastName
                }
            
            TextField("Last Name", text: $lastName)
                .multilineTextAlignment(.center)
                .keyboardType(.asciiCapable)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .lastName)
                .font(.title2)
                .padding()
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal)

            Spacer()

            Button(action: {
                Task {
                    guard var user = authManager.currentUser else { return }
                    user.firstName = firstName
                    user.lastName = lastName

                    let success = await authManager.updateProfile(updatedUser: user)
                    if success {
                        authManager.registeredName = true
                        // authManager.completed = true
                        navigateToEnterCreditCard = true
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
            .disabled(isDisabled)
            .padding(.horizontal)
            .padding(.bottom)  // Adjust button position based on keyboard height

        }
        .padding(.top)
        .onAppear {
            // Set focus to the text field when the view appears
            focusedField = .firstName
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
        .navigationDestination(isPresented: $navigateToEnterCreditCard) {
            SearchCardsView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RegisterNameView()
}
