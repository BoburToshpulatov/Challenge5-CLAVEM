import SwiftData
import Foundation

extension AppStore {

    // MARK: - Load from SwiftData

    func load(from context: ModelContext) {
        do {
            let propertyEntities = try context.fetch(FetchDescriptor<PropertyEntity>())
            let tenantEntities = try context.fetch(FetchDescriptor<TenantEntity>())
            let billEntities = try context.fetch(FetchDescriptor<BillEntity>())
            let billShareEntities = try context.fetch(FetchDescriptor<BillShareEntity>())
            let paymentEntities = try context.fetch(FetchDescriptor<PaymentRecordEntity>())
            let occupancyEntities = try context.fetch(FetchDescriptor<OccupancyRecordEntity>())

            properties = propertyEntities
                .map { entity in
                    Property(
                        id: entity.id,
                        name: entity.name,
                        addressLine: entity.addressLine,
                        city: entity.city,
                        rentalMode: RentalMode(rawValue: entity.rentalModeRaw) ?? .wholeProperty,
                        billsEnabled: entity.billsEnabled,
                        imageName: entity.imageName,
                        imageData: entity.imageData,
                        rooms: entity.rooms
                            .map {
                                Room(
                                    id: $0.id,
                                    name: $0.name,
                                    note: $0.note
                                )
                            }
                            .sorted {
                                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                            },
                        note: entity.note
                    )
                }
                .sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

            tenants = tenantEntities
                .map { entity in
                    Tenant(
                        id: entity.id,
                        propertyID: entity.propertyID,
                        roomID: entity.roomID,
                        name: entity.name,
                        imageName: entity.imageName,
                        imageData: entity.imageData,
                        monthlyRent: entity.monthlyRent,
                        scheduledDayOfMonth: entity.scheduledDayOfMonth,
                        nextDueDate: entity.nextDueDate,
                        activeDelay: entity.activeDelay,
                        moveInDate: entity.moveInDate,
                        moveOutDate: entity.moveOutDate,
                        isActive: entity.isActive,
                        note: entity.note
                    )
                }
                .sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

            bills = billEntities
                .map { entity in
                    Bill(
                        id: entity.id,
                        propertyID: entity.propertyID,
                        type: BillType(rawValue: entity.typeRaw) ?? .other,
                        title: entity.title,
                        note: entity.note,
                        totalAmount: entity.totalAmount,
                        billDate: entity.billDate,
                        dueDate: entity.dueDate,
                        photoData: entity.photoData,
                        isIncludedInTenantPayments: entity.isIncludedInTenantPayments
                    )
                }
                .sorted { $0.billDate > $1.billDate }

            billShares = billShareEntities
                .map {
                    BillShare(
                        id: $0.id,
                        billID: $0.billID,
                        tenantID: $0.tenantID,
                        amount: $0.amount,
                        billingMonth: $0.billingMonth,
                        isPaid: $0.isPaid
                    )
                }
                .sorted { $0.billingMonth > $1.billingMonth }

            payments = paymentEntities
                .map {
                    PaymentRecord(
                        id: $0.id,
                        tenantID: $0.tenantID,
                        propertyID: $0.propertyID,
                        dueDate: $0.dueDate,
                        paidDate: $0.paidDate,
                        baseRentAmount: $0.baseRentAmount,
                        billPortionAmount: $0.billPortionAmount,
                        totalAmount: $0.totalAmount,
                        note: $0.note
                    )
                }
                .sorted { ($0.paidDate ?? $0.dueDate) > ($1.paidDate ?? $1.dueDate) }

            occupancyHistory = occupancyEntities
                .map {
                    OccupancyRecord(
                        id: $0.id,
                        propertyID: $0.propertyID,
                        roomID: $0.roomID,
                        tenantNameSnapshot: $0.tenantNameSnapshot,
                        moveInDate: $0.moveInDate,
                        moveOutDate: $0.moveOutDate,
                        finalMonthlyRent: $0.finalMonthlyRent,
                        note: $0.note
                    )
                }
                .sorted { $0.moveInDate > $1.moveInDate }

        } catch {
            print("SwiftData load error:", error)
        }
    }

    // MARK: - Save to SwiftData

    func save(to context: ModelContext) {
        do {
            try context.delete(model: PropertyEntity.self)
            try context.delete(model: TenantEntity.self)
            try context.delete(model: BillEntity.self)
            try context.delete(model: BillShareEntity.self)
            try context.delete(model: PaymentRecordEntity.self)
            try context.delete(model: OccupancyRecordEntity.self)

            try context.save()

            for property in properties {
                let entity = PropertyEntity(
                    id: property.id,
                    name: property.name,
                    addressLine: property.addressLine,
                    city: property.city,
                    rentalModeRaw: property.rentalMode.rawValue,
                    billsEnabled: property.billsEnabled,
                    imageName: property.imageName,
                    imageData: property.imageData,
                    note: property.note
                )

                entity.rooms = property.rooms.map {
                    RoomEntity(
                        id: $0.id,
                        name: $0.name,
                        note: $0.note
                    )
                }

                context.insert(entity)
            }

            for tenant in tenants {
                let entity = TenantEntity(
                    id: tenant.id,
                    propertyID: tenant.propertyID,
                    roomID: tenant.roomID,
                    name: tenant.name,
                    imageName: tenant.imageName,
                    imageData: tenant.imageData,
                    monthlyRent: tenant.monthlyRent,
                    scheduledDayOfMonth: tenant.scheduledDayOfMonth,
                    nextDueDate: tenant.nextDueDate,
                    moveInDate: tenant.moveInDate,
                    moveOutDate: tenant.moveOutDate,
                    isActive: tenant.isActive,
                    note: tenant.note
                )

                entity.activeDelay = tenant.activeDelay
                context.insert(entity)
            }

            for bill in bills {
                let entity = BillEntity(
                    id: bill.id,
                    propertyID: bill.propertyID,
                    typeRaw: bill.type.rawValue,
                    title: bill.title,
                    note: bill.note,
                    totalAmount: bill.totalAmount,
                    billDate: bill.billDate,
                    dueDate: bill.dueDate,
                    photoData: bill.photoData,
                    isIncludedInTenantPayments: bill.isIncludedInTenantPayments
                )

                context.insert(entity)
            }

            for share in billShares {
                let entity = BillShareEntity(
                    id: share.id,
                    billID: share.billID,
                    tenantID: share.tenantID,
                    amount: share.amount,
                    billingMonth: share.billingMonth,
                    isPaid: share.isPaid
                )

                context.insert(entity)
            }

            for payment in payments {
                let entity = PaymentRecordEntity(
                    id: payment.id,
                    tenantID: payment.tenantID,
                    propertyID: payment.propertyID,
                    dueDate: payment.dueDate,
                    paidDate: payment.paidDate,
                    baseRentAmount: payment.baseRentAmount,
                    billPortionAmount: payment.billPortionAmount,
                    totalAmount: payment.totalAmount,
                    note: payment.note
                )

                context.insert(entity)
            }

            for record in occupancyHistory {
                let entity = OccupancyRecordEntity(
                    id: record.id,
                    propertyID: record.propertyID,
                    roomID: record.roomID,
                    tenantNameSnapshot: record.tenantNameSnapshot,
                    moveInDate: record.moveInDate,
                    moveOutDate: record.moveOutDate,
                    finalMonthlyRent: record.finalMonthlyRent,
                    note: record.note
                )

                context.insert(entity)
            }

            try context.save()

        } catch {
            print("SwiftData save error:", error)
        }
    }
}
