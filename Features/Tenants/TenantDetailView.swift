import SwiftUI

struct TenantDetailView: View {

    @Bindable var store: AppStore
    let tenantID: Tenant.ID

    private let pagePadding: CGFloat = 16

    @State private var tenantToEdit: Tenant? = nil
    @State private var pendingArchiveTenant: Tenant? = nil
    @State private var showPaidConfirmation = false
    @State private var showReminderShare = false
    @State private var showDelaySheet = false

    private var tenant: Tenant? {
        store.tenants.first(where: { $0.id == tenantID })
    }

    private var property: Property? {
        guard let tenant = tenant else { return nil }
        return store.properties.first(where: { $0.id == tenant.propertyID })
    }

    private var paymentHistory: [PaymentRecord] {
        store.payments
            .filter { $0.tenantID == tenantID }
            .sorted { ($0.paidDate ?? $0.dueDate) > ($1.paidDate ?? $1.dueDate) }
    }

    private var currentUpcomingPayment: UpcomingPayment? {
        store.upcomingPayments.first(where: { $0.tenantID == tenantID })
    }

    private var reminderText: String {
        guard let item = currentUpcomingPayment else { return "" }
        return store.reminderMessage(for: item)
    }

    var body: some View {
        if let tenant = tenant {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    header(tenant)

                    actionsSection(tenant)

                    summarySection(tenant)

                    if let property = property {
                        propertySection(property, tenant: tenant)
                    }

                    breakdownSection(tenant)

                    activeBillsSection(tenant)

                    if let note = tenant.note, !note.isEmpty {
                        notesSection(note)
                    }

                    paymentHistorySection

                    archiveSection(tenant)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tenant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        tenantToEdit = tenant
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit tenant")
                }
            }
            .sheet(item: $tenantToEdit) { tenant in
                AddTenantView(
                    store: store,
                    tenant: tenant
                )
            }
            .sheet(isPresented: $showReminderShare) {
                ShareSheet(items: [reminderText])
            }
            .sheet(isPresented: $showDelaySheet) {
                delaySheetContent
            }
            .confirmationDialog(
                "Mark payment as paid?",
                isPresented: $showPaidConfirmation,
                titleVisibility: .visible
            ) {
                Button("Mark as Paid", role: .destructive) {
                    store.markPaid(tenantID: tenant.id)
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will record the current payment and move the next due date forward.")
            }
            .confirmationDialog(
                "Archive tenant?",
                isPresented: Binding(
                    get: { pendingArchiveTenant != nil },
                    set: { if !$0 { pendingArchiveTenant = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Archive", role: .destructive) {
                    guard let tenant = pendingArchiveTenant else { return }
                    store.archiveTenant(tenant.id)
                    pendingArchiveTenant = nil
                }

                Button("Cancel", role: .cancel) {
                    pendingArchiveTenant = nil
                }
            } message: {
                if let tenant = pendingArchiveTenant {
                    Text("This will move \(tenant.name) out of active tenants and preserve their occupancy history.")
                }
            }
        } else {
            ContentUnavailableView(
                "Tenant not found",
                systemImage: "person.crop.circle.badge.exclamationmark"
            )
        }
    }
}

private extension TenantDetailView {

    var delaySheetContent: some View {
        Group {
            if let tenant = tenant {
                DelayTenantSheet(
                    currentDueDate: tenant.activeDelay?.newDueDate ?? tenant.nextDueDate
                ) { newDate in
                    store.setDelay(
                        tenantID: tenant.id,
                        newDueDate: newDate
                    )
                }
            } else {
                ContentUnavailableView(
                    "Tenant not found",
                    systemImage: "person.crop.circle.badge.exclamationmark"
                )
            }
        }
    }

    func header(_ tenant: Tenant) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                AvatarView(
                    name: tenant.name,
                    imageName: tenant.imageName,
                    imageData: tenant.imageData,
                    size: CGSize(width: 92, height: 92),
                    cornerRadius: 28
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(tenant.name)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.leading)

                    if let property = property {
                        Text(property.name)
                            .font(.headline)
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }

                    if let roomName = store.roomName(for: tenant) {
                        Text(roomName)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.72))
                    } else {
                        Text("Whole property tenant")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, pagePadding)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }

    func actionsSection(_ tenant: Tenant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.title3.bold())

            HStack(spacing: 10) {
                Button("Paid") {
                    showPaidConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("Delay") {
                    showDelaySheet = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Remind") {
                    showReminderShare = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(reminderText.isEmpty)
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func summarySection(_ tenant: Tenant) -> some View {
        let currentAmount = store.currentAmountDue(for: tenant)
        let status = store.status(for: tenant)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                StatPill(
                    title: "Amount Due",
                    value: currentAmount,
                    isCurrency: true
                )

                StatPill(
                    title: "Status",
                    value: status.rawValue.capitalized
                )
            }

            sectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(
                        title: "Base rent",
                        value: tenant.monthlyRent.formatted(.currency(code: "EUR"))
                    )

                    detailRow(
                        title: "Next payment date",
                        value: (tenant.activeDelay?.newDueDate ?? tenant.nextDueDate)
                            .formatted(date: .long, time: .omitted)
                    )

                    if let delay = tenant.activeDelay {
                        detailRow(
                            title: "Original due date",
                            value: delay.originalDueDate.formatted(date: .abbreviated, time: .omitted)
                        )
                    }

                    detailRow(
                        title: "Move in",
                        value: tenant.moveInDate.formatted(date: .abbreviated, time: .omitted)
                    )

                    if let moveOutDate = tenant.moveOutDate {
                        detailRow(
                            title: "Move out",
                            value: moveOutDate.formatted(date: .abbreviated, time: .omitted)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func propertySection(_ property: Property, tenant: Tenant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property")
                .font(.title3.bold())

            sectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(title: "Property", value: property.name)
                    detailRow(title: "Address", value: "\(property.addressLine), \(property.city)")
                    detailRow(
                        title: "Rental mode",
                        value: property.rentalMode == .wholeProperty ? "Whole property" : "By rooms"
                    )

                    if let roomName = store.roomName(for: tenant) {
                        detailRow(title: "Room", value: roomName)
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func breakdownSection(_ tenant: Tenant) -> some View {
        let billLines = store.billBreakdownText(for: tenant, month: tenant.nextDueDate)
        let billAmount = store.unpaidBillPortion(for: tenant, month: tenant.nextDueDate)
        let total = store.currentAmountDue(for: tenant)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Current payment breakdown")
                .font(.title3.bold())

            sectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(
                        title: "Rent",
                        value: tenant.monthlyRent.formatted(.currency(code: "EUR"))
                    )

                    if billLines.isEmpty {
                        detailRow(title: "Bills", value: "No additional bills")
                    } else {
                        ForEach(billLines, id: \.self) { line in
                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(Color.primary.opacity(0.72))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        detailRow(
                            title: "Bill portion total",
                            value: billAmount.formatted(.currency(code: "EUR"))
                        )
                    }

                    Divider()

                    detailRow(
                        title: "Total due",
                        value: total.formatted(.currency(code: "EUR")),
                        emphasized: true
                    )
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func activeBillsSection(_ tenant: Tenant) -> some View {
        let shares = store.unpaidBillShares(for: tenant, month: tenant.nextDueDate)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Bills in this cycle")
                .font(.title3.bold())

            if shares.isEmpty {
                sectionCard {
                    Text("No active bills in this payment cycle")
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(shares) { share in
                        if let bill = store.bills.first(where: { $0.id == share.billID }) {
                            sectionCard {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bill.title)
                                            .font(.headline)

                                        Text(bill.type.title)
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))

                                        if let note = bill.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(Color.primary.opacity(0.72))
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(share.amount, format: .currency(code: "EUR"))
                                            .font(.subheadline.weight(.semibold))

                                        Text(bill.billDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))
                                    }
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func notesSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.title3.bold())

            sectionCard {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, pagePadding)
    }

    var paymentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment history")
                .font(.title3.bold())

            if paymentHistory.isEmpty {
                sectionCard {
                    Text("No payment history yet")
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(paymentHistory) { record in
                        sectionCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.dueDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.headline)

                                        if let paidDate = record.paidDate {
                                            Text("Paid on \(paidDate.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundStyle(Color.primary.opacity(0.72))
                                        } else {
                                            Text("Not paid")
                                                .font(.caption)
                                                .foregroundStyle(Color.primary.opacity(0.72))
                                        }

                                        if let note = record.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(Color.primary.opacity(0.72))
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(record.totalAmount.formatted(.currency(code: "EUR")))
                                            .font(.subheadline.weight(.semibold))

                                        if record.billPortionAmount > 0 {
                                            Text("incl. \(record.billPortionAmount.formatted(.currency(code: "EUR"))) bills")
                                                .font(.caption2)
                                                .foregroundStyle(Color.primary.opacity(0.72))
                                        }
                                    }
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 6) {
                                    detailRow(
                                        title: "Rent portion",
                                        value: record.baseRentAmount.formatted(.currency(code: "EUR"))
                                    )

                                    detailRow(
                                        title: "Bill portion",
                                        value: record.billPortionAmount.formatted(.currency(code: "EUR"))
                                    )
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func archiveSection(_ tenant: Tenant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tenant status")
                .font(.title3.bold())

            sectionCard {
                Button(role: .destructive) {
                    pendingArchiveTenant = tenant
                } label: {
                    HStack {
                        Text("Archive tenant")
                            .font(.headline)

                        Spacer()

                        Image(systemName: "archivebox")
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func detailRow(
        title: String,
        value: String,
        emphasized: Bool = false
    ) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.72))

            Spacer(minLength: 12)

            Text(value)
                .font(emphasized ? .subheadline.weight(.bold) : .subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }
}

private struct DelayTenantSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date
    let onSave: (Date) -> Void

    init(currentDueDate: Date, onSave: @escaping (Date) -> Void) {
        _selectedDate = State(initialValue: max(Date(), currentDueDate))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "New due date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                } footer: {
                    Text("Choose a later payment date for this tenant.")
                }
            }
            .navigationTitle("Delay Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}
