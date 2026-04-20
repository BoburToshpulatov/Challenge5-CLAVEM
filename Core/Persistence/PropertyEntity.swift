//
//  PropertyEntity.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 08/03/26.
//


import Foundation
import SwiftData

@Model
final class PropertyEntity {
    var id: UUID
    var name: String
    var addressLine: String
    var city: String

    var rentalModeRaw: String
    var billsEnabled: Bool

    var imageName: String?
    var imageData: Data?
    var note: String?

    @Relationship(deleteRule: .cascade)
    var rooms: [RoomEntity]

    @Relationship(deleteRule: .cascade)
    var tenants: [TenantEntity]

    @Relationship(deleteRule: .cascade)
    var bills: [BillEntity]

    @Relationship(deleteRule: .cascade)
    var occupancyHistory: [OccupancyRecordEntity]

    init(
        id: UUID = UUID(),
        name: String,
        addressLine: String,
        city: String,
        rentalModeRaw: String,
        billsEnabled: Bool,
        imageName: String? = nil,
        imageData: Data? = nil,
        note: String? = nil,
        rooms: [RoomEntity] = [],
        tenants: [TenantEntity] = [],
        bills: [BillEntity] = [],
        occupancyHistory: [OccupancyRecordEntity] = []
    ) {
        self.id = id
        self.name = name
        self.addressLine = addressLine
        self.city = city
        self.rentalModeRaw = rentalModeRaw
        self.billsEnabled = billsEnabled
        self.imageName = imageName
        self.imageData = imageData
        self.note = note
        self.rooms = rooms
        self.tenants = tenants
        self.bills = bills
        self.occupancyHistory = occupancyHistory
    }
}

@Model
final class RoomEntity {
    var id: UUID
    var name: String
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.note = note
    }
}