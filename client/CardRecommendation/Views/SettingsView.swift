import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var navigateToPersonalInfo = false
    @State private var safeAreaInsets = EdgeInsets()
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Your content
                    menuSection(title: "Personal information", subtitle: "Activity across all accounts") {
                        navigateToPersonalInfo = true
                    }

                    Divider()
                    .background(Color.gray)
                    .padding(.horizontal)

                    // 👇 Fills remaining space only if needed
                    Spacer()

                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("Log out")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(Color.blue, lineWidth: 1)
                            )
                            .padding()
                    }
                    .hapticTap()
                    .padding(.bottom)
                }
                .frame(minHeight: geo.size.height)
            }
        }
        .navigationDestination(isPresented: $navigateToPersonalInfo) {
            PersonalInfoView()
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
                Text("Settings")
                    .foregroundColor(.white)
            }
        }
    }
    
    // Helper function for menu items
    private func menuSection(title: String, subtitle: String, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            action?()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 20)
            .padding(.horizontal)
        }
    }
}
