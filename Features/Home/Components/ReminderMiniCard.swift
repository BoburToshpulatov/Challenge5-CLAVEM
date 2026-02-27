import SwiftUI


struct ReminderMiniCard: View {
    let item: UpcomingPayment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            AvatarView(
                name: item.tenantName,
                imageName: item.tenantImageName,
                size: CGSize(width: 44, height: 44),
                cornerRadius: 14
            )

            Text(item.tenantName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Text(item.dueDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 120, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}
