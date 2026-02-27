//
//  AppStore.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 22/02/26.
//


import Foundation
import Observation

@Observable
final class AppStore {

    // Source of truth
    var properties: [Property] = []
    var tenants: [Tenant] = []
    var payments: [PaymentRecord] = [] // history + paid state

    init() {}

    // MARK: - Derived: Upcoming payments (Reminders)
    var upcomingPayments: [UpcomingPayment] {
        let propertyByID = Dictionary(uniqueKeysWithValues: properties.map { ($0.id, $0) })

        return tenants.map { tenant in
            let propertyName = propertyByID[tenant.propertyID]?.name ?? "Property"
            let dueDate = tenant.activeDelay?.newDueDate ?? tenant.nextDueDate

            return UpcomingPayment(
                tenantID: tenant.id,
                tenantName: tenant.name,
                tenantImageName: tenant.imageName,   // 👈 ADD THIS
                propertyName: propertyName,
                dueDate: dueDate,
                amount: tenant.monthlyRent,
                isDelayed: tenant.activeDelay != nil
            )
        }
        .sorted { $0.dueDate < $1.dueDate }
    }


    // MARK: - This month only (for Reminders + Home summary)
    var upcomingPaymentsThisMonth: [UpcomingPayment] {
        let cal = Calendar.current
        let now = Date()

        return upcomingPayments
            .filter { cal.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var upcomingThisMonthCount: Int {
        upcomingPaymentsThisMonth.count
    }

    var upcomingPreviewThisMonth: [UpcomingPayment] {
        Array(upcomingPaymentsThisMonth.prefix(3))
    }

    var nextDueThisMonth: UpcomingPayment? {
        upcomingPaymentsThisMonth.first
    }


    func tenants(for property: Property) -> [Tenant] {
        tenants.filter { $0.propertyID == property.id }
    }

    func tenantCount(for property: Property) -> Int {
        tenants(for: property).count
    }

    func monthlyIncome(for property: Property) -> Decimal {
        tenants(for: property).reduce(0) { $0 + $1.monthlyRent }
    }

    func addProperty(_ property: Property) {
        properties.append(property)
    }

    func updateProperty(_ property: Property) {
        guard let idx = properties.firstIndex(where: { $0.id == property.id }) else { return }
        properties[idx] = property
    }

    func deleteProperty(_ id: Property.ID) {
        properties.removeAll { $0.id == id }
        tenants.removeAll { $0.propertyID == id } // optional cascade (recommended)
    }

    // MARK: - Grouped by property (best for landlords)
    var remindersGroupedThisMonth: [(propertyName: String, items: [UpcomingPayment])] {
        let grouped = Dictionary(grouping: upcomingPaymentsThisMonth, by: { $0.propertyName })

        return grouped
            .map { (propertyName: $0.key, items: $0.value.sorted { $0.dueDate < $1.dueDate }) }
            .sorted { $0.propertyName.localizedCaseInsensitiveCompare($1.propertyName) == .orderedAscending }
    }

    // MARK: - Dashboard stats (simple for now)
    var expectedMonthlyIncome: Decimal {
        tenants.reduce(0) { $0 + $1.monthlyRent }
    }

    var nextDue: UpcomingPayment? { upcomingPayments.first }

    // MARK: - Actions
    func markPaid(tenantID: Tenant.ID) {
        guard let idx = tenants.firstIndex(where: { $0.id == tenantID }) else { return }
        let tenant = tenants[idx]

        let dueDate = tenant.activeDelay?.newDueDate ?? tenant.nextDueDate
        let amount = tenant.monthlyRent

        // Save history record
        payments.append(
            PaymentRecord(
                tenantID: tenant.id,
                propertyID: tenant.propertyID,
                dueDate: dueDate,
                amount: amount,
                paidDate: .now
            )
        )

        // Clear delay once paid
        tenants[idx].activeDelay = nil

        // Move next due date by 1 month (basic monthly schedule)
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: dueDate) {
            tenants[idx].nextDueDate = next
        }
    }

    func setDelay(tenantID: Tenant.ID, newDueDate: Date, reason: String? = nil) {
        guard let idx = tenants.firstIndex(where: { $0.id == tenantID }) else { return }
        let original = tenants[idx].nextDueDate
        tenants[idx].activeDelay = PaymentDelay(originalDueDate: original, newDueDate: newDueDate, reason: reason)
    }
}


enum PaymentStatus: String, Hashable {
    case paid
    case due
    case overdue
    case delayed
}

extension AppStore {
    func propertyName(for tenant: Tenant) -> String {
        properties.first(where: { $0.id == tenant.propertyID })?.name ?? "Property"
    }

    func status(for tenant: Tenant) -> PaymentStatus {
        let dueDate = tenant.activeDelay?.newDueDate ?? tenant.nextDueDate

        if tenant.activeDelay != nil {
            return dueDate < Date() ? .overdue : .delayed
        }

        if dueDate < Date() { return .overdue }

        let isPaid = payments.contains { record in
            record.tenantID == tenant.id &&
            record.dueDate == dueDate &&
            record.paidDate != nil
        }

        return isPaid ? .paid : .due
    }
}
