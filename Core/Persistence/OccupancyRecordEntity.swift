//
//  OccupancyRecordEntity.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 08/03/26.
//


import Foundation
import SwiftData

@Model
final class OccupancyRecordEntity {
    var id: UUID

    var propertyID: UUID
    var roomID: UUID?

    var tenantNameSnapshot: String

    var moveInDate: Date
    var moveOutDate: Date?

    var finalMonthlyRent: Decimal
    var note: String?

    init(
        id: UUID = UUID(),
        propertyID: UUID,
        roomID: UUID? = nil,
        tenantNameSnapshot: String,
        moveInDate: Date,
        moveOutDate: Date? = nil,
        finalMonthlyRent: Decimal,
        note: String? = nil
    ) {
        self.id = id
        self.propertyID = propertyID
        self.roomID = roomID
        self.tenantNameSnapshot = tenantNameSnapshot
        self.moveInDate = moveInDate
        self.moveOutDate = moveOutDate
        self.finalMonthlyRent = finalMonthlyRent
        self.note = note
    }
}