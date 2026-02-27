//
//  Property.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 22/02/26.
//


import Foundation

// MARK: - Property
import Foundation

struct Property: Identifiable, Hashable {
    let id: UUID
    var name: String
    var addressLine: String
    var city: String

    // ✅ Keep your existing asset name support
    var imageName: String?

    // ✅ New: uploaded photo stored in memory for now (later we’ll persist to disk)
    var imageData: Data?

    // ✅ Rooms. If empty → whole property rental.
    var rooms: [Room]

    init(
        id: UUID = UUID(),
        name: String,
        addressLine: String,
        city: String,
        imageName: String? = nil,
        imageData: Data? = nil,
        rooms: [Room] = []
    ) {
        self.id = id
        self.name = name
        self.addressLine = addressLine
        self.city = city
        self.imageName = imageName
        self.imageData = imageData
        self.rooms = rooms
    }
}

// MARK: - Tenant
struct Tenant: Identifiable, Hashable {
    let id: UUID
    var propertyID: Property.ID
    var name: String
    var imageName: String?
    var monthlyRent: Decimal

    /// Next scheduled due date (can be shifted by delay)
    var nextDueDate: Date

    /// If user grants a delay, store it here (nil = no delay)
    var activeDelay: PaymentDelay?

    init(
        id: UUID = UUID(),
        propertyID: Property.ID,
        name: String,
        imageName: String? = nil,
        monthlyRent: Decimal,
        nextDueDate: Date,
        activeDelay: PaymentDelay? = nil
    ) {
        self.id = id
        self.propertyID = propertyID
        self.name = name
        self.imageName = imageName
        self.monthlyRent = monthlyRent
        self.nextDueDate = nextDueDate
        self.activeDelay = activeDelay
    }
}

// MARK: - Payment Delay
struct PaymentDelay: Hashable {
    var originalDueDate: Date
    var newDueDate: Date
    var reason: String?
}

// MARK: - Payment Record (history)
struct PaymentRecord: Identifiable, Hashable {
    let id: UUID
    var tenantID: Tenant.ID
    var propertyID: Property.ID
    var dueDate: Date
    var amount: Decimal
    var paidDate: Date?

    var isPaid: Bool { paidDate != nil }

    init(
        id: UUID = UUID(),
        tenantID: Tenant.ID,
        propertyID: Property.ID,
        dueDate: Date,
        amount: Decimal,
        paidDate: Date? = nil
    ) {
        self.id = id
        self.tenantID = tenantID
        self.propertyID = propertyID
        self.dueDate = dueDate
        self.amount = amount
        self.paidDate = paidDate
    }
}

// MARK: - Upcoming Payment (for Reminders + Home preview)
struct UpcomingPayment: Identifiable, Hashable {
    let id: UUID
    var tenantID: Tenant.ID
    var tenantName: String
    var tenantImageName: String?   // 👈 ADD THIS
    var propertyName: String
    var dueDate: Date
    var amount: Decimal
    var isDelayed: Bool

    init(
        id: UUID = UUID(),
        tenantID: Tenant.ID,
        tenantName: String,
        tenantImageName: String?,
        propertyName: String,
        dueDate: Date,
        amount: Decimal,
        isDelayed: Bool
    ) {
        self.id = id
        self.tenantID = tenantID
        self.tenantName = tenantName
        self.tenantImageName = tenantImageName
        self.propertyName = propertyName
        self.dueDate = dueDate
        self.amount = amount
        self.isDelayed = isDelayed
    }
}
