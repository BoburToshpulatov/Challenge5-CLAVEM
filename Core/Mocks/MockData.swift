import Foundation

enum MockData {

    static func makeStore() -> AppStore {
        let store = AppStore()

        // MARK: - Properties

        let cityLoft = Property(
            name: "City Loft",
            addressLine: "Via Roma 12",
            city: "Milan",
            rentalMode: .wholeProperty,
            billsEnabled: true,
            imageName: nil,
            imageData: nil,
            rooms: [],
            note: "Central apartment close to metro."
        )

        let navigliHouse = Property(
            name: "Navigli House",
            addressLine: "Corso Como 8",
            city: "Milan",
            rentalMode: .byRooms,
            billsEnabled: true,
            imageName: nil,
            imageData: nil,
            rooms: [
                Room(name: "Room A"),
                Room(name: "Room B"),
                Room(name: "Room C")
            ],
            note: "Shared apartment with 3 private rooms."
        )

        store.properties = [cityLoft, navigliHouse]

        // MARK: - Tenants

        let today = Date()
        let calendar = Calendar.current

        let loftTenant = Tenant(
            propertyID: cityLoft.id,
            roomID: nil,
            name: "Marco Rossi",
            imageName: nil,
            imageData: nil,
            monthlyRent: 1250,
            nextDueDate: makeDate(day: 18, fallbackFrom: today),
            moveInDate: calendar.date(byAdding: .month, value: -4, to: today) ?? today,
            note: "Pays on time usually."
        )

        let roomATenant = Tenant(
            propertyID: navigliHouse.id,
            roomID: navigliHouse.rooms[0].id,
            name: "Sara Bianchi",
            imageName: nil,
            imageData: nil,
            monthlyRent: 650,
            nextDueDate: makeDate(day: 12, fallbackFrom: today),
            moveInDate: calendar.date(byAdding: .month, value: -7, to: today) ?? today,
            note: "Prefers WhatsApp reminders."
        )

        let roomBTenant = Tenant(
            propertyID: navigliHouse.id,
            roomID: navigliHouse.rooms[1].id,
            name: "Luca Conti",
            imageName: nil,
            imageData: nil,
            monthlyRent: 690,
            nextDueDate: makeDate(day: 8, fallbackFrom: today),
            activeDelay: PaymentDelay(
                originalDueDate: makeDate(day: 8, fallbackFrom: today),
                newDueDate: makeDate(day: 14, fallbackFrom: today),
                reason: "Asked for a short extension"
            ),
            moveInDate: calendar.date(byAdding: .month, value: -2, to: today) ?? today,
            note: "Recently requested a short delay."
        )

        store.tenants = [loftTenant, roomATenant, roomBTenant]

        // MARK: - Previous occupant history

        store.occupancyHistory = [
            OccupancyRecord(
                propertyID: navigliHouse.id,
                roomID: navigliHouse.rooms[2].id,
                tenantNameSnapshot: "Anna Verdi",
                moveInDate: calendar.date(byAdding: .year, value: -1, to: today) ?? today,
                moveOutDate: calendar.date(byAdding: .month, value: -1, to: today) ?? today,
                finalMonthlyRent: 620,
                note: "Moved out after contract end."
            )
        ]

        // MARK: - Bills

        let waterBill = Bill(
            propertyID: navigliHouse.id,
            type: .water,
            title: "Water Bill",
            note: "Quarterly water bill",
            totalAmount: 90,
            billDate: monthStart(from: today),
            dueDate: calendar.date(byAdding: .day, value: 10, to: today),
            photoData: nil,
            isIncludedInTenantPayments: true
        )

        let gasBill = Bill(
            propertyID: cityLoft.id,
            type: .gas,
            title: "Gas Bill",
            note: "Monthly gas bill",
            totalAmount: 65,
            billDate: monthStart(from: today),
            dueDate: calendar.date(byAdding: .day, value: 7, to: today),
            photoData: nil,
            isIncludedInTenantPayments: true
        )

        store.addBill(waterBill)
        store.addBill(gasBill)

        // MARK: - Previous payment history

        if let lastMonthDue = calendar.date(byAdding: .month, value: -1, to: loftTenant.nextDueDate) {
            store.payments.append(
                PaymentRecord(
                    tenantID: loftTenant.id,
                    propertyID: loftTenant.propertyID,
                    dueDate: lastMonthDue,
                    paidDate: calendar.date(byAdding: .day, value: -20, to: today),
                    baseRentAmount: 1250,
                    billPortionAmount: 0,
                    totalAmount: 1250,
                    note: "Paid on time"
                )
            )
        }

        if let lastMonthDue = calendar.date(byAdding: .month, value: -1, to: roomATenant.nextDueDate) {
            store.payments.append(
                PaymentRecord(
                    tenantID: roomATenant.id,
                    propertyID: roomATenant.propertyID,
                    dueDate: lastMonthDue,
                    paidDate: calendar.date(byAdding: .day, value: -16, to: today),
                    baseRentAmount: 650,
                    billPortionAmount: 30,
                    totalAmount: 680,
                    note: "Included previous utility split"
                )
            )
        }

        return store
    }

    // MARK: - Helpers

    private static func makeDate(day: Int, fallbackFrom base: Date) -> Date {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: base)
        comps.day = day
        comps.hour = 12
        return calendar.date(from: comps) ?? base
    }

    private static func monthStart(from date: Date) -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }
}
