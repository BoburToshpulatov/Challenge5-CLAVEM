//
//  TenantEntity.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 08/03/26.
//


import Foundation
import SwiftData

@Model
final class TenantEntity {
    var id: UUID

    var propertyID: UUID
    var roomID: UUID?

    var name: String
    var imageName: String?
    var imageData: Data?

    var monthlyRent: Decimal
    var scheduledDayOfMonth: Int
    var nextDueDate: Date

    var activeDelayOriginalDueDate: Date?
    var activeDelayNewDueDate: Date?
    var activeDelayReason: String?

    var moveInDate: Date
    var moveOutDate: Date?
    var isActive: Bool
    var note: String?

    init(
        id: UUID = UUID(),
        propertyID: UUID,
        roomID: UUID? = nil,
        name: String,
        imageName: String? = nil,
        imageData: Data? = nil,
        monthlyRent: Decimal,
        scheduledDayOfMonth: Int,
        nextDueDate: Date,
        activeDelayOriginalDueDate: Date? = nil,
        activeDelayNewDueDate: Date? = nil,
        activeDelayReason: String? = nil,
        moveInDate: Date = .now,
        moveOutDate: Date? = nil,
        isActive: Bool = true,
        note: String? = nil
    ) {
        self.id = id
        self.propertyID = propertyID
        self.roomID = roomID
        self.name = name
        self.imageName = imageName
        self.imageData = imageData
        self.monthlyRent = monthlyRent
        self.scheduledDayOfMonth = scheduledDayOfMonth
        self.nextDueDate = nextDueDate
        self.activeDelayOriginalDueDate = activeDelayOriginalDueDate
        self.activeDelayNewDueDate = activeDelayNewDueDate
        self.activeDelayReason = activeDelayReason
        self.moveInDate = moveInDate
        self.moveOutDate = moveOutDate
        self.isActive = isActive
        self.note = note
    }
}

extension TenantEntity {
    var activeDelay: PaymentDelay? {
        get {
            guard
                let original = activeDelayOriginalDueDate,
                let newDate = activeDelayNewDueDate
            else {
                return nil
            }

            return PaymentDelay(
                originalDueDate: original,
                newDueDate: newDate,
                reason: activeDelayReason
            )
        }
        set {
            activeDelayOriginalDueDate = newValue?.originalDueDate
            activeDelayNewDueDate = newValue?.newDueDate
            activeDelayReason = newValue?.reason
        }
    }
}