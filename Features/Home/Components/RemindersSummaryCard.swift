import SwiftUI

struct RemindersSummaryCard: View {
    let countThisMonth: Int
    let nextDue: UpcomingPayment?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Upcoming payments")
                    .font(.headline)

                Spacer()

                Text("\(countThisMonth) this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let nextDue {
                HStack(spacing: 12) {
                    AvatarView(
                        name: nextDue.tenantName,
                        imageName: nextDue.tenantImageName,
                        size: CGSize(width: 44, height: 44),
                        cornerRadius: 14
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(nextDue.tenantName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)

                            if nextDue.isDelayed {
                                Text("Delayed")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundStyle(Color.blue)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(nextDue.propertyName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(nextDue.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(nextDue.amount, format: .currency(code: "EUR"))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            } else {
                Text("No payments due this month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
