import SwiftUI

struct UpcomingPaymentCard: View {

    let item: UpcomingPayment
    let messageText: String
    let onRemind: (String) -> Void
    let onDelay: (Date) -> Void
    let onConfirmPaid: () -> Void

    @State private var showPaidConfirm = false
    @State private var showCalendar = false
    @State private var selectedDate = Date()

    private let radius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            header

            if showCalendar {
                calendarSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .opacity(0.12)

            actions
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .confirmationDialog(
            "Mark this payment as paid?",
            isPresented: $showPaidConfirm,
            titleVisibility: .visible
        ) {
            Button("Mark as Paid", role: .destructive) {
                onConfirmPaid()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will move the payment to the Paid tab.")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

private extension UpcomingPaymentCard {

    var header: some View {
        HStack(alignment: .top, spacing: 12) {

            AvatarView(
                name: item.tenantName,
                imageName: item.tenantImageName,
                imageData: nil,
                size: CGSize(width: 48, height: 48),
                cornerRadius: 16
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {

                HStack(alignment: .top, spacing: 8) {
                    Text(item.tenantName)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if item.isDelayed {
                        StatusChip(text: "Delayed", kind: .info)
                    }
                }

                HStack(spacing: 8) {
                    StatusChip(text: statusText, kind: statusKind)

                    Text(item.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 3) {
                    amountRow(
                        title: "Rent",
                        amount: item.baseRentAmount,
                        emphasized: false
                    )

                    if item.billPortionAmount > 0 {
                        amountRow(
                            title: "Bills",
                            amount: item.billPortionAmount,
                            emphasized: false
                        )
                    }

                    amountRow(
                        title: "Total due",
                        amount: item.amount,
                        emphasized: true
                    )
                }
            }

            Spacer(minLength: 0)
        }
    }

    var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Select new payment date")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            DatePicker(
                "",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .frame(maxHeight: 320)
            .clipped()

            HStack(spacing: 10) {

                Button("Cancel") {
                    closeCalendar()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button("Confirm delay") {
                    onDelay(selectedDate)
                    closeCalendar()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 2)
    }

    var actions: some View {
        HStack(spacing: 10) {

            Button("Remind") {
                onRemind(messageText)
            }
            .buttonStyle(ActionPillStyle(kind: .remind))

            Button("Delay") {
                selectedDate = max(Date(), item.dueDate)
                openCalendar()
            }
            .buttonStyle(ActionPillStyle(kind: .delay))
            .disabled(showCalendar)

            Button("Paid") {
                showPaidConfirm = true
            }
            .buttonStyle(ActionPillStyle(kind: .paid))
        }
    }

    func amountRow(
        title: String,
        amount: Decimal,
        emphasized: Bool
    ) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .subheadline.weight(.semibold) : .caption)
                .foregroundStyle(emphasized ? .primary : .secondary)

            Spacer(minLength: 10)

            Text(amount, format: .currency(code: "EUR"))
                .font(emphasized ? .subheadline.weight(.bold) : .caption.weight(.semibold))
                .foregroundStyle(emphasized ? .primary : .secondary)
        }
    }

    func openCalendar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showCalendar = true
        }
    }

    func closeCalendar() {
        withAnimation(.easeInOut(duration: 0.18)) {
            showCalendar = false
        }
    }

    var statusText: String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: item.dueDate
        ).day ?? 0

        if days > 1 { return "Due in \(days)d" }
        if days == 1 { return "Tomorrow" }
        if days == 0 { return "Today" }
        return "\(abs(days))d overdue"
    }

    var statusKind: StatusChip.Kind {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: item.dueDate
        ).day ?? 0

        if days < 0 { return .danger }
        if days <= 2 { return .warning }
        return .neutral
    }

    var accessibilityLabel: String {
        let delayed = item.isDelayed ? ", delayed" : ""
        return "\(item.tenantName), total due \(item.amount.formatted(.currency(code: "EUR"))), rent \(item.baseRentAmount.formatted(.currency(code: "EUR"))), bills \(item.billPortionAmount.formatted(.currency(code: "EUR"))), due \(item.dueDate.formatted(date: .long, time: .omitted))\(delayed)"
    }
}

private struct StatusChip: View {
    enum Kind { case neutral, warning, danger, info }

    let text: String
    let kind: Kind

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var background: Color {
        switch kind {
        case .neutral: return Color.secondary.opacity(0.15)
        case .warning: return Color.orange.opacity(0.18)
        case .danger:  return Color.red.opacity(0.18)
        case .info:    return Color.indigo.opacity(0.18)
        }
    }

    private var foreground: Color {
        switch kind {
        case .neutral: return .secondary
        case .warning: return .orange
        case .danger:  return .red
        case .info:    return .indigo
        }
    }
}
