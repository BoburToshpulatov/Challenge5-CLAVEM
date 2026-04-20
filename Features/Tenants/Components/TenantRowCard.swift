import SwiftUI

struct TenantRowCard: View {

    let tenant: Tenant
    let propertyName: String
    let status: PaymentStatus

    private let radius: CGFloat = 18

    var body: some View {
        HStack(spacing: 12) {

            AvatarView(
                name: tenant.name,
                imageName: tenant.imageName,
                imageData: tenant.imageData,
                size: CGSize(width: 48, height: 48),
                cornerRadius: 14
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {

                Text(tenant.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(propertyName)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.68))
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 6) {

                Text(
                    tenant.monthlyRent,
                    format: .currency(code: "EUR")
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

                Text(statusText)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens tenant details")
    }

    private var statusText: String {
        switch status {
        case .paid: return "Paid"
        case .due: return "Due"
        case .overdue: return "Overdue"
        case .delayed: return "Delayed"
        }
    }

    private var statusColor: Color {
        switch status {
        case .paid: return .green
        case .due: return .orange
        case .overdue: return .red
        case .delayed: return .blue
        }
    }

    private var accessibilityLabel: String {
        "\(tenant.name), \(propertyName), \(tenant.monthlyRent.formatted(.currency(code: "EUR"))), \(statusText)"
    }
}
