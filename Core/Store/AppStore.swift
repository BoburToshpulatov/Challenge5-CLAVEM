import Foundation
import Observation

@Observable
final class AppStore {

    // MARK: - Source of truth

    var properties: [Property] = []
    var tenants: [Tenant] = []
    var payments: [PaymentRecord] = []

    var bills: [Bill] = []
    var billShares: [BillShare] = []
    var occupancyHistory: [OccupancyRecord] = []

    var paymentInstructions = PaymentInstructions(
        payToName: "Landlord",
        iban: nil,
        cardLast4: nil,
        note: "Please include your name in the payment reference."
    )

    init() {}

    // MARK: - Date helpers

    private var calendar: Calendar { .current }

    private var todayStart: Date {
        calendar.startOfDay(for: Date())
    }

    func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    func monthStart(for date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    // MARK: - Property helpers

    func tenants(for property: Property) -> [Tenant] {
        tenants.filter { $0.propertyID == property.id && $0.isActive }
    }

    func allTenants(for property: Property) -> [Tenant] {
        tenants.filter { $0.propertyID == property.id }
    }

    func tenantCount(for property: Property) -> Int {
        tenants(for: property).count
    }

    func monthlyIncome(for property: Property) -> Decimal {
        tenants(for: property).reduce(0) { $0 + $1.monthlyRent }
    }

    func propertyName(for tenant: Tenant) -> String {
        properties.first(where: { $0.id == tenant.propertyID })?.name ?? "Property"
    }

    func property(for tenant: Tenant) -> Property? {
        properties.first(where: { $0.id == tenant.propertyID })
    }

    func roomName(for tenant: Tenant) -> String? {
        guard
            let property = property(for: tenant),
            let roomID = tenant.roomID
        else { return nil }

        return property.rooms.first(where: { $0.id == roomID })?.name
    }

    // MARK: - Property actions

    func addProperty(_ property: Property) {
        properties.append(property)
    }

    func updateProperty(_ property: Property) {
        guard let idx = properties.firstIndex(where: { $0.id == property.id }) else { return }
        properties[idx] = property
    }

    func deleteProperty(_ id: Property.ID) {
        let deletedBillIDs = Set(
            bills
                .filter { $0.propertyID == id }
                .map(\.id)
        )

        let affectedTenants = tenants.filter { $0.propertyID == id }

        properties.removeAll { $0.id == id }
        tenants.removeAll { $0.propertyID == id }
        payments.removeAll { $0.propertyID == id }
        bills.removeAll { $0.propertyID == id }
        occupancyHistory.removeAll { $0.propertyID == id }
        billShares.removeAll { deletedBillIDs.contains($0.billID) }

        for tenant in affectedTenants {
            Task {
                await NotificationManager.shared.removePaymentReminder(for: tenant.id)
            }
        }
    }

    // MARK: - Tenant actions

    func addTenant(_ tenant: Tenant) {
        tenants.append(tenant)

        Task {
            await NotificationManager.shared.schedulePaymentReminder(
                tenantID: tenant.id,
                tenantName: tenant.name,
                propertyName: propertyName(for: tenant),
                dueDate: tenant.activeDelay?.newDueDate ?? tenant.nextDueDate,
                amountText: currentAmountDue(for: tenant).formatted(.currency(code: "EUR"))
            )
        }
    }

    func updateTenant(_ tenant: Tenant) {
        guard let idx = tenants.firstIndex(where: { $0.id == tenant.id }) else { return }
        tenants[idx] = tenant

        Task {
            await NotificationManager.shared.removePaymentReminder(for: tenant.id)
            guard tenant.isActive else { return }

            await NotificationManager.shared.schedulePaymentReminder(
                tenantID: tenant.id,
                tenantName: tenant.name,
                propertyName: propertyName(for: tenant),
                dueDate: tenant.activeDelay?.newDueDate ?? tenant.nextDueDate,
                amountText: currentAmountDue(for: tenant).formatted(.currency(code: "EUR"))
            )
        }
    }

    func archiveTenant(_ tenantID: Tenant.ID, moveOutDate: Date = .now, note: String? = nil) {
        guard let idx = tenants.firstIndex(where: { $0.id == tenantID }) else { return }

        let tenant = tenants[idx]

        occupancyHistory.append(
            OccupancyRecord(
                propertyID: tenant.propertyID,
                roomID: tenant.roomID,
                tenantNameSnapshot: tenant.name,
                moveInDate: tenant.moveInDate,
                moveOutDate: moveOutDate,
                finalMonthlyRent: tenant.monthlyRent,
                note: note
            )
        )

        tenants[idx].isActive = false
        tenants[idx].moveOutDate = moveOutDate

        Task {
            await NotificationManager.shared.removePaymentReminder(for: tenant.id)
        }
    }

    // MARK: - Room / rental mode logic

    func wholePropertyTenant(for property: Property) -> Tenant? {
        tenants.first {
            $0.propertyID == property.id &&
            $0.roomID == nil &&
            $0.isActive
        }
    }

    func roomTenants(for property: Property) -> [Tenant] {
        tenants.filter {
            $0.propertyID == property.id &&
            $0.roomID != nil &&
            $0.isActive
        }
    }

    func canAddTenant(to property: Property, roomID: Room.ID?) -> Bool {
        switch property.rentalMode {
        case .wholeProperty:
            let existingWhole = wholePropertyTenant(for: property)
            return existingWhole == nil && roomID == nil

        case .byRooms:
            guard let roomID else { return false }
            return !tenants.contains {
                $0.propertyID == property.id &&
                $0.roomID == roomID &&
                $0.isActive
            }
        }
    }

    // MARK: - Bills

    func addBill(_ bill: Bill) {
        bills.append(bill)

        guard bill.isIncludedInTenantPayments else { return }
        guard let property = properties.first(where: { $0.id == bill.propertyID }) else { return }
        guard property.billsEnabled else { return }

        let activeTenants = tenants(for: property)
        guard !activeTenants.isEmpty else { return }

        let splitMonth = monthStart(for: bill.billDate)

        switch property.rentalMode {
        case .wholeProperty:
            guard let tenant = wholePropertyTenant(for: property) else { return }

            billShares.append(
                BillShare(
                    billID: bill.id,
                    tenantID: tenant.id,
                    amount: bill.totalAmount,
                    billingMonth: splitMonth,
                    isPaid: false
                )
            )

            Task {
                await NotificationManager.shared.removePaymentReminder(for: tenant.id)
                await NotificationManager.shared.schedulePaymentReminder(
                    tenantID: tenant.id,
                    tenantName: tenant.name,
                    propertyName: propertyName(for: tenant),
                    dueDate: tenant.activeDelay?.newDueDate ?? tenant.nextDueDate,
                    amountText: currentAmountDue(for: tenant).formatted(.currency(code: "EUR"))
                )
            }

        case .byRooms:
            let count = Decimal(activeTenants.count)
            guard count > 0 else { return }

            let share = bill.totalAmount / count

            for tenant in activeTenants {
                billShares.append(
                    BillShare(
                        billID: bill.id,
                        tenantID: tenant.id,
                        amount: share,
                        billingMonth: splitMonth,
                        isPaid: false
                    )
                )

                Task {
                    await NotificationManager.shared.removePaymentReminder(for: tenant.id)
                    await NotificationManager.shared.schedulePaymentReminder(
                        tenantID: tenant.id,
                        tenantName: tenant.name,
                        propertyName: propertyName(for: tenant),
                        dueDate: tenant.activeDelay?.newDueDate ?? tenant.nextDueDate,
                        amountText: currentAmountDue(for: tenant).formatted(.currency(code: "EUR"))
                    )
                }
            }
        }
    }

    func bills(for property: Property) -> [Bill] {
        bills
            .filter { $0.propertyID == property.id }
            .sorted { $0.billDate > $1.billDate }
    }

    func billShares(for tenant: Tenant) -> [BillShare] {
        billShares
            .filter { $0.tenantID == tenant.id }
            .sorted { $0.billingMonth > $1.billingMonth }
    }

    func unpaidBillShares(for tenant: Tenant, month: Date? = nil) -> [BillShare] {
        let targetMonth = month.map(monthStart)

        return billShares.filter { share in
            guard share.tenantID == tenant.id, share.isPaid == false else { return false }

            if let targetMonth {
                return monthStart(for: share.billingMonth) == targetMonth
            } else {
                return true
            }
        }
    }

    func unpaidBillPortion(for tenant: Tenant, month: Date? = nil) -> Decimal {
        unpaidBillShares(for: tenant, month: month).reduce(0) { $0 + $1.amount }
    }

    func billBreakdownText(for tenant: Tenant, month: Date? = nil) -> [String] {
        let shares = unpaidBillShares(for: tenant, month: month)

        return shares.compactMap { share in
            guard let bill = bills.first(where: { $0.id == share.billID }) else { return nil }
            let amount = share.amount.formatted(.currency(code: "EUR"))
            return "\(bill.title): \(amount)"
        }
    }

    // MARK: - Current amount due

    func currentAmountDue(for tenant: Tenant) -> Decimal {
        let billPortion = unpaidBillPortion(for: tenant, month: tenant.nextDueDate)
        return tenant.monthlyRent + billPortion
    }

    // MARK: - Upcoming Payments

    var upcomingPayments: [UpcomingPayment] {
        let propertyByID = Dictionary(uniqueKeysWithValues: properties.map { ($0.id, $0) })

        return tenants
            .filter { $0.isActive }
            .map { tenant in
                let propertyName = propertyByID[tenant.propertyID]?.name ?? "Property"
                let dueDate = tenant.activeDelay?.newDueDate ?? tenant.nextDueDate
                let billPortion = unpaidBillPortion(for: tenant, month: tenant.nextDueDate)
                let total = tenant.monthlyRent + billPortion

                return UpcomingPayment(
                    tenantID: tenant.id,
                    tenantName: tenant.name,
                    tenantImageName: tenant.imageName,
                    propertyName: propertyName,
                    dueDate: dueDate,
                    baseRentAmount: tenant.monthlyRent,
                    billPortionAmount: billPortion,
                    amount: total,
                    isDelayed: tenant.activeDelay != nil
                )
            }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var upcomingPaymentsThisMonth: [UpcomingPayment] {
        upcomingPayments.filter { isCurrentMonth($0.dueDate) }
    }

    var upcomingThisMonth: [UpcomingPayment] {
        upcomingPaymentsThisMonth
            .filter { $0.dueDate >= todayStart }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var overdueThisMonth: [UpcomingPayment] {
        upcomingPaymentsThisMonth
            .filter { $0.dueDate < todayStart }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var upcomingThisMonthCount: Int {
        upcomingPaymentsThisMonth.count
    }

    var nextDueThisMonth: UpcomingPayment? {
        upcomingThisMonth.first
    }

    var upcomingPreviewThisMonth: [UpcomingPayment] {
        Array(upcomingThisMonth.prefix(3))
    }

    var nextDue: UpcomingPayment? {
        upcomingPayments.first
    }

    // MARK: - Paid tab

    var paidPaymentsThisMonth: [PaidPayment] {
        let tenantByID = Dictionary(uniqueKeysWithValues: tenants.map { ($0.id, $0) })
        let propertyByID = Dictionary(uniqueKeysWithValues: properties.map { ($0.id, $0) })

        return payments
            .filter { record in
                guard let paid = record.paidDate else { return false }
                return isCurrentMonth(paid)
            }
            .sorted { ($0.paidDate ?? .distantPast) > ($1.paidDate ?? .distantPast) }
            .map { record in
                let tenant = tenantByID[record.tenantID]
                let propertyName = propertyByID[record.propertyID]?.name ?? "Property"

                return PaidPayment(
                    id: record.id,
                    tenantID: record.tenantID,
                    tenantName: tenant?.name ?? "Tenant",
                    tenantImageName: tenant?.imageName,
                    propertyName: propertyName,
                    amount: record.totalAmount,
                    paidDate: record.paidDate ?? .now,
                    dueDate: record.dueDate
                )
            }
    }

    // MARK: - Dashboard stats

    var expectedMonthlyIncome: Decimal {
        tenants
            .filter { $0.isActive }
            .reduce(0) { $0 + currentAmountDue(for: $1) }
    }

    // MARK: - Payment status

    func status(for tenant: Tenant) -> PaymentStatus {
        let effectiveDue = tenant.activeDelay?.newDueDate ?? tenant.nextDueDate

        if tenant.activeDelay != nil {
            return effectiveDue < Date() ? .overdue : .delayed
        }

        if effectiveDue < Date() { return .overdue }

        let isPaid = payments.contains { record in
            record.tenantID == tenant.id &&
            record.dueDate == effectiveDue &&
            record.paidDate != nil
        }

        return isPaid ? .paid : .due
    }

    // MARK: - Mark paid

    func markPaid(tenantID: Tenant.ID) {
        guard let idx = tenants.firstIndex(where: { $0.id == tenantID }) else { return }

        let tenant = tenants[idx]
        let scheduledDue = tenant.nextDueDate
        let effectiveDue = tenant.activeDelay?.newDueDate ?? scheduledDue

        let billPortion = unpaidBillPortion(for: tenant, month: tenant.nextDueDate)
        let total = tenant.monthlyRent + billPortion

        payments.append(
            PaymentRecord(
                tenantID: tenant.id,
                propertyID: tenant.propertyID,
                dueDate: effectiveDue,
                paidDate: .now,
                baseRentAmount: tenant.monthlyRent,
                billPortionAmount: billPortion,
                totalAmount: total
            )
        )

        for shareIndex in billShares.indices {
            if billShares[shareIndex].tenantID == tenant.id &&
                monthStart(for: billShares[shareIndex].billingMonth) == monthStart(for: tenant.nextDueDate) &&
                billShares[shareIndex].isPaid == false {
                billShares[shareIndex].isPaid = true
            }
        }

        tenants[idx].activeDelay = nil
        tenants[idx].nextDueDate = nextScheduledDate(
            after: scheduledDue,
            scheduledDay: tenants[idx].scheduledDayOfMonth
        )

        let updatedTenant = tenants[idx]

        Task {
            await NotificationManager.shared.removePaymentReminder(for: tenant.id)
            await NotificationManager.shared.schedulePaymentReminder(
                tenantID: updatedTenant.id,
                tenantName: updatedTenant.name,
                propertyName: propertyName(for: updatedTenant),
                dueDate: updatedTenant.nextDueDate,
                amountText: currentAmountDue(for: updatedTenant).formatted(.currency(code: "EUR"))
            )
        }
    }

    func setDelay(tenantID: Tenant.ID, newDueDate: Date, reason: String? = nil) {
        guard let idx = tenants.firstIndex(where: { $0.id == tenantID }) else { return }

        let original = tenants[idx].nextDueDate

        tenants[idx].activeDelay = PaymentDelay(
            originalDueDate: original,
            newDueDate: newDueDate,
            reason: reason
        )

        let updatedTenant = tenants[idx]

        Task {
            await NotificationManager.shared.removePaymentReminder(for: updatedTenant.id)
            await NotificationManager.shared.schedulePaymentReminder(
                tenantID: updatedTenant.id,
                tenantName: updatedTenant.name,
                propertyName: propertyName(for: updatedTenant),
                dueDate: newDueDate,
                amountText: currentAmountDue(for: updatedTenant).formatted(.currency(code: "EUR"))
            )
        }
    }

    // MARK: - Reminder message

    func reminderMessage(for item: UpcomingPayment) -> String {
        let days = calendar.dateComponents([.day], from: Date(), to: item.dueDate).day ?? 0
        let date = item.dueDate.formatted(date: .long, time: .omitted)
        let amount = item.amount.formatted(.currency(code: "EUR"))

        guard let tenant = tenants.first(where: { $0.id == item.tenantID }) else {
            return "Payment of \(amount) is due on \(date)."
        }

        var lines: [String] = []
        lines.append("Hi \(item.tenantName),")

        if item.isDelayed {
            lines.append("")
            lines.append("As agreed, your payment of \(amount) is due on \(date).")
        } else if days >= 10 {
            lines.append("")
            lines.append("Friendly reminder: your payment of \(amount) is due on \(date).")
        } else if days >= 3 {
            lines.append("")
            lines.append("Reminder: your payment of \(amount) is due on \(date).")
        } else if days == 0 {
            lines.append("")
            lines.append("Today is the due date for your payment of \(amount).")
        } else {
            lines.append("")
            lines.append("Your payment of \(amount) was due on \(date) and hasn’t been received yet.")
        }

        lines.append("")
        lines.append("Rent: \(item.baseRentAmount.formatted(.currency(code: "EUR")))")

        let billLines = billBreakdownText(for: tenant, month: tenant.nextDueDate)
        if !billLines.isEmpty {
            for billLine in billLines {
                lines.append(billLine)
            }
        }

        if let iban = paymentInstructions.iban {
            lines.append("")
            lines.append("IBAN: \(iban)")
        }

        if let last4 = paymentInstructions.cardLast4 {
            lines.append("Card: **** \(last4)")
        }

        if let note = paymentInstructions.note {
            lines.append(note)
        }

        lines.append("")
        lines.append("Thank you.")

        return lines.joined(separator: "\n")
    }

    // MARK: - Scheduling

    private func daysInMonth(year: Int, month: Int) -> Int {
        let comps = DateComponents(year: year, month: month)
        let date = calendar.date(from: comps) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func nextScheduledDate(after scheduledDue: Date, scheduledDay: Int) -> Date {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: scheduledDue) else {
            return scheduledDue
        }

        let year = calendar.component(.year, from: nextMonth)
        let month = calendar.component(.month, from: nextMonth)
        let maxDay = daysInMonth(year: year, month: month)
        let day = min(max(scheduledDay, 1), maxDay)

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12

        return calendar.date(from: comps) ?? nextMonth
    }
}

enum PaymentStatus: String, Hashable {
    case paid
    case due
    case overdue
    case delayed
}
