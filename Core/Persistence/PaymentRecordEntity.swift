//
//  PaymentRecordEntity.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 08/03/26.
//


import Foundation
import SwiftData

@Model
final class PaymentRecordEntity {
    var id: UUID

    var tenantID: UUID
    var propertyID: UUID

    var dueDate: Date
    var paidDate: Date?

    var baseRentAmount: Decimal
    var billPortionAmount: Decimal
    var totalAmount: Decimal

    var note: String?

    init(
        id: UUID = UUID(),
        tenantID: UUID,
        propertyID: UUID,
        dueDate: Date,
        paidDate: Date? = nil,
        baseRentAmount: Decimal,
        billPortionAmount: Decimal = 0,
        totalAmount: Decimal,
        note: String? = nil
    ) {
        self.id = id
        self.tenantID = tenantID
        self.propertyID = propertyID
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.baseRentAmount = baseRentAmount
        self.billPortionAmount = billPortionAmount
        self.totalAmount = totalAmount
        self.note = note
    }
}