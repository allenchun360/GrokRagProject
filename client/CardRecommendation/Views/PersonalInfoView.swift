import SwiftUI

struct PersonalInfoView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var safeAreaInsets = EdgeInsets()
    @State private var showAlert = false
    
    var user: User? {
        authManager.currentUser
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack {
                    // Contact Information
                    sectionHeader("Contact information")

                    InfoRow(title: "Name", value: "\(user?.firstName ?? "") \(user?.lastName ?? "")", disabled: true)
                    if let phone = user?.phoneNumber {
                        InfoRow(
                            title: "Phone number",
                            value: formatPhoneNumber(phoneNumberString: cleanPhoneNumber(phoneNumberString: phone)),
                            verified: true
                        )
                        Divider()
                        .background(Color.gray)
                        .padding(.horizontal)
                    }

                    Spacer()

                    Button(action: {
                        showAlert = true
                        // Task {
                        //     await authManager.deleteAccount()
                        // }
                    }) {
                        Text("Delete account")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(Color.red, lineWidth: 1)
                            )
                            .padding()
                    }
                    .alert("Delete Account", isPresented: $showAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete Account", role: .destructive) {
                            Task {
                                await authManager.deleteAccount()
                            }
                        }
                    } message: {
                        Text("Are you sure you want to delete your account? All your data will be erased.")
                    }
                    .hapticTap()
                    .padding(.bottom)
                }
                .padding(.top, 30)
                .frame(minHeight: geo.size.height)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.safeAreaInsets) { oldValue, newValue in
                        safeAreaInsets = newValue
                    }
            }
        )
        .overlay(alignment: .top) {
            // change to whatever color/view you need or UIVisualEffectView to keep the blur
            Color.black
                .frame(height: safeAreaInsets.top)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(Color(.black), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Personal Information")
                    .foregroundColor(.white)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - InfoRow

struct InfoRow: View {
    let title: String
    let value: String
    var verified: Bool = false
    var multiline: Bool = false
    var disabled: Bool = false

    var body: some View {
        Button(action: {}) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.gray)
                    if multiline {
                        Text(value)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(value)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                if verified {
                    HStack(spacing: 6) {
                        Text("Verified")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .disabled(disabled)
    }
}

// MARK: - SimpleRow

struct SimpleRow: View {
    let title: String
    var subtitle: String? = nil
    var subtitleStyle: Color = .white

    var body: some View {
        Button(action: {}) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(subtitle == nil ? .white : .gray)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .foregroundColor(subtitleStyle)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}
