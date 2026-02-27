import SwiftUI
import Foundation

struct PropertyCard: View {
    let property: Property

    private let radius: CGFloat = 20
    private let height: CGFloat = 240   // 🔁 original height restored

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Background image
            AvatarView(
                name: property.name,
                imageName: property.imageName,
                size: CGSize(width: UIScreen.main.bounds.width - 32, height: height),
                cornerRadius: radius
            )

            // Gradient
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.15),
                    .black.opacity(0.85)
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            // Details back to bottom
            VStack(alignment: .leading) {
                Text(property.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(property.addressLine), \(property.city)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(18)
            .padding(.bottom, 22)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
    }
}
