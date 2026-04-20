import SwiftUI

struct RemindersSummaryCard: View {
    let countThisMonth: Int
    let nextDue: UpcomingPayment?


    private let radius: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            header

            if let nextDue {
                nextDueRow(nextDue)
            } else {
                emptyState
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
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens reminders")
    }
}

private extension RemindersSummaryCard {

    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Upcoming payments")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Text("\(countThisMonth) this month")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.68))
        }
    }

    func nextDueRow(_ nextDue: UpcomingPayment) -> some View {
        HStack(spacing: 12) {

            AvatarView(
                name: nextDue.tenantName,
                imageName: nextDue.tenantImageName,
                imageData: nil,
                size: CGSize(width: 48, height: 48),
                cornerRadius: 14
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(nextDue.tenantName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if nextDue.isDelayed {
                        delayedBadge
                    }
                }

                Text(nextDue.propertyName)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.68))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(nextDue.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.68))

                Text(nextDue.amount, format: .currency(code: "EUR"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    var emptyState: some View {
        Text("No payments due this month")
            .font(.subheadline)
            .foregroundStyle(Color.primary.opacity(0.72))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var delayedBadge: some View {
        Text("Delayed")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
            .lineLimit(1)
    }

    var accessibilityLabel: String {
        if let nextDue {
            let delayedText = nextDue.isDelayed ? ", delayed" : ""
            return "Upcoming payments, \(countThisMonth) this month. Next due: \(nextDue.tenantName), \(nextDue.amount.formatted(.currency(code: "EUR"))), due \(nextDue.dueDate.formatted(date: .long, time: .omitted))\(delayedText)."
        } else {
            return "Upcoming payments. No payments due this month."
        }
    }
}
