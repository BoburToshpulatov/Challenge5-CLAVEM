import SwiftUI

struct TenantCardLarge: View {
    let tenant: Tenant
    let propertyName: String
    let status: PaymentStatus

    private let radius: CGFloat = 24
    private let imageHeight: CGFloat = 170

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            GeometryReader { geo in
                AvatarView(
                    name: tenant.name,
                    imageName: tenant.imageName,
                    imageData: tenant.imageData,
                    size: CGSize(width: geo.size.width, height: imageHeight),
                    cornerRadius: 18
                )
            }
            .frame(height: imageHeight)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tenant.name)
                            .font(.title3.bold())
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(propertyName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    statusChip
                }

                HStack {
                    Text(tenant.monthlyRent, format: .currency(code: "EUR"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("Monthly rent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
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

    private var statusChip: some View {
        Text(statusText)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.14))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }

    private var accessibilityLabel: String {
        "\(tenant.name), \(propertyName), \(tenant.monthlyRent.formatted(.currency(code: "EUR"))) monthly rent, \(statusText)"
    }

    private var cardBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    private var borderColor: Color {
        Color.primary.opacity(0.08)
    }
}
