import SwiftUI

struct CreditCardView: View {
    var height: CGFloat
    var width: CGFloat? = nil
    var issuer: String
    var card_name: String
    var showInfo: Bool = false
    var rank: Int? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.9), .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
            .frame(width: width, height: height)
            .overlay(
                VStack {
                    HStack(alignment: .firstTextBaseline) {
                        Text(issuer)
                            .font(.system(.body, design: .monospaced))
                            .textCase(.uppercase)
                        Spacer()
                        Image(systemName: "creditcard")
                            .resizable()
                            .frame(width: 30, height: 20)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    HStack {
                        Text(card_name)
                            .font(.subheadline)
                        Spacer()
                        if showInfo {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .font(.body)
                        }
                    }
                }
                .padding()
            )
            .overlay(alignment: .bottomTrailing) {
                if let rank = rank {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 40, height: 40)
                        Text("\(rank)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    .padding(12)
                }
            }
    }
}
