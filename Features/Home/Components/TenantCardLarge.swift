import SwiftUI

struct TenantCardLarge: View {
    let tenant: Tenant
    let propertyName: String
    let status: PaymentStatus

    private let radius: CGFloat = 24
    private let imageHeight: CGFloat = 170

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Artwork / Avatar (fills card width via GeometryReader)
            GeometryReader { geo in
                AvatarView(
                    name: tenant.name,
                    imageName: tenant.imageName,
                    size: CGSize(width: geo.size.width, height: imageHeight),
                    cornerRadius: 18
                )
            }
            .frame(height: imageHeight)

            VStack(alignment: .leading, spacing: 6) {

                Text(tenant.name)
                    .font(.title3.bold())
                    .lineLimit(1)

                Text(propertyName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(statusColor)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }


        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
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
}
