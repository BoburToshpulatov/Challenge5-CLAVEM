import SwiftUI

struct PropertyListCardLarge: View {
    let property: Property
    let tenantCount: Int
    let monthlyIncome: Decimal

    private let radius: CGFloat = 22

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            AvatarView(
                name: property.name,
                imageName: property.imageName,
                imageData: property.imageData,
                size: CGSize(width: 78, height: 78),
                cornerRadius: 22
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .leading, spacing: 4) {
                    Text(property.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(property.addressLine), \(property.city)")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                chipWrap

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Monthly income")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.68))

                    Spacer(minLength: 8)

                    Text(monthlyIncome, format: .currency(code: "EUR"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to open property details")
    }

    private var chipWrap: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                metaChip(title: "\(tenantCount) tenants")
                metaChip(title: rentalModeText)
            }

            if property.billsEnabled {
                HStack(spacing: 8) {
                    metaChip(title: "Bills enabled", tint: .indigo)
                }
            }
        }
    }

    private var rentalModeText: String {
        switch property.rentalMode {
        case .wholeProperty:
            return "Whole property"
        case .byRooms:
            return "\(property.rooms.count) rooms"
        }
    }

    private func metaChip(
        title: String,
        tint: Color = .secondary
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .clipShape(Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }

    private var accessibilityLabel: String {
        let billsText = property.billsEnabled
            ? "Bill splitting enabled"
            : "Bill splitting disabled"

        return "\(property.name), \(property.addressLine), \(property.city), \(tenantCount) tenants, \(monthlyIncome.formatted(.currency(code: "EUR"))) monthly income, \(rentalModeText), \(billsText)"
    }
}
