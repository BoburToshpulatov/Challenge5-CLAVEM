import SwiftUI

struct PropertyListCardLarge: View {
    let property: Property
    let tenantCount: Int
    let monthlyIncome: Decimal

    private let radius: CGFloat = 22

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(
                name: property.name,
                imageName: property.imageName,
                imageData: property.imageData,
                size: CGSize(width: 84, height: 84),
                cornerRadius: 24
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(property.name)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(property.addressLine), \(property.city)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(tenantCount)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(monthlyIncome, format: .currency(code: "EUR"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if property.rooms.isEmpty {
                        Text("Whole property")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(property.rooms.count) rooms")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}
