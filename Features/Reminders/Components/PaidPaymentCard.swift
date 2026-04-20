import SwiftUI

struct PaidPaymentCard: View {
    let paid: PaidPayment

    private let radius: CGFloat = 20

    var body: some View {
        HStack(spacing: 12) {

            AvatarView(
                name: paid.tenantName,
                imageName: paid.tenantImageName,
                imageData: nil,
                size: CGSize(width: 46, height: 46),
                cornerRadius: 14
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(paid.tenantName)
                        .font(.headline)
                        .lineLimit(1)

                    statusBadge
                }

                Text(paid.propertyName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("Paid \(paid.paidDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(paid.amount, format: .currency(code: "EUR"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Due \(paid.dueDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var statusBadge: some View {
        Text("Paid")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.14))
            .foregroundStyle(.green)
            .clipShape(Capsule())
            .lineLimit(1)
    }

    private var accessibilityLabel: String {
        "\(paid.tenantName), \(paid.propertyName), paid \(paid.amount.formatted(.currency(code: "EUR"))) on \(paid.paidDate.formatted(date: .long, time: .omitted))"
    }
}
