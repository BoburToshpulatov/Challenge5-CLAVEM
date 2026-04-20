//
//  BillEntity.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 08/03/26.
//


import Foundation
import SwiftData

@Model
final class BillEntity {
    var id: UUID

    var propertyID: UUID
    var typeRaw: String
    var title: String
    var note: String?

    var totalAmount: Decimal
    var billDate: Date
    var dueDate: Date?

    var photoData: Data?
    var isIncludedInTenantPayments: Bool

    @Relationship(deleteRule: .cascade)
    var shares: [BillShareEntity]

    init(
        id: UUID = UUID(),
        propertyID: UUID,
        typeRaw: String,
        title: String,
        note: String? = nil,
        totalAmount: Decimal,
        billDate: Date = .now,
        dueDate: Date? = nil,
        photoData: Data? = nil,
        isIncludedInTenantPayments: Bool = true,
        shares: [BillShareEntity] = []
    ) {
        self.id = id
        self.propertyID = propertyID
        self.typeRaw = typeRaw
        self.title = title
        self.note = note
        self.totalAmount = totalAmount
        self.billDate = billDate
        self.dueDate = dueDate
        self.photoData = photoData
        self.isIncludedInTenantPayments = isIncludedInTenantPayments
        self.shares = shares
    }
}

@Model
final class BillShareEntity {
    var id: UUID

    var billID: UUID
    var tenantID: UUID
    var amount: Decimal
    var billingMonth: Date
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        billID: UUID,
        tenantID: UUID,
        amount: Decimal,
        billingMonth: Date,
        isPaid: Bool = false
    ) {
        self.id = id
        self.billID = billID
        self.tenantID = tenantID
        self.amount = amount
        self.billingMonth = billingMonth
        self.isPaid = isPaid
    }
}

extension BillEntity {
    var billType: BillType {
        get { BillType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}