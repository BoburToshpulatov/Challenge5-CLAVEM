import SwiftUI

struct UpcomingPaymentCard: View {
    let item: UpcomingPayment
    let onDelay: () -> Void
    let onConfirmPaid: () -> Void

    @State private var showPaidConfirm = false
    private let radius: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Top Row
            HStack(alignment: .center, spacing: 14) {

                AvatarView(
                    name: item.tenantName,
                    imageName: item.tenantImageName,
                    size: CGSize(width: 60, height: 60),
                    cornerRadius: 20
                )

                VStack(alignment: .leading, spacing: 4) {

                    HStack(spacing: 8) {
                        Text(item.tenantName)
                            .font(.headline)

                        if item.isDelayed {
                            Text("Delayed")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }

                    Text(item.propertyName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(item.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text(item.amount, format: .currency(code: "EUR"))
                    .font(.title3.weight(.semibold))
            }

            // Divider (very subtle, optional but elegant)
            Divider()
                .opacity(0.15)

            // Buttons Row
            HStack(spacing: 12) {

                Button("Delay") {
                    onDelay()
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Spacer()

                Button("Paid") {
                    showPaidConfirm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(18)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .confirmationDialog(
            "Mark this payment as paid?",
            isPresented: $showPaidConfirm,
            titleVisibility: .visible
        ) {
            Button("Mark as Paid", role: .destructive) {
                withAnimation(.snappy) {
                    onConfirmPaid()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
