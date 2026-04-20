import Foundation

extension AppStore {

    var activePropertiesCount: Int {
        properties.count
    }

    var activeTenantsCount: Int {
        tenants.filter(\.isActive).count
    }

    var expectedThisMonthIncome: Decimal {
        upcomingPaymentsThisMonth.reduce(0) { $0 + $1.amount }
    }

    var collectedThisMonthIncome: Decimal {
        paidPaymentsThisMonth.reduce(0) { $0 + $1.amount }
    }

    var overdueAmountThisMonth: Decimal {
        overdueThisMonth.reduce(0) { $0 + $1.amount }
    }

    var outstandingThisMonthIncome: Decimal {
        max(expectedThisMonthIncome - collectedThisMonthIncome, 0)
    }

    var occupiedUnitsCount: Int {
        properties.reduce(0) { result, property in
            switch property.rentalMode {
            case .wholeProperty:
                return result + (wholePropertyTenant(for: property) == nil ? 0 : 1)

            case .byRooms:
                let occupiedRooms = property.rooms.filter { room in
                    tenants.contains {
                        $0.propertyID == property.id &&
                        $0.roomID == room.id &&
                        $0.isActive
                    }
                }.count
                return result + occupiedRooms
            }
        }
    }

    var totalUnitsCount: Int {
        properties.reduce(0) { result, property in
            switch property.rentalMode {
            case .wholeProperty:
                return result + 1
            case .byRooms:
                return result + property.rooms.count
            }
        }
    }

    var occupancyRateText: String {
        guard totalUnitsCount > 0 else { return "0%" }
        let percent = Int((Double(occupiedUnitsCount) / Double(totalUnitsCount)) * 100)
        return "\(percent)%"
    }

    var collectionRateText: String {
        let expected = expectedThisMonthIncome as NSDecimalNumber
        let collected = collectedThisMonthIncome as NSDecimalNumber

        guard expected.doubleValue > 0 else { return "0%" }

        let percent = Int((collected.doubleValue / expected.doubleValue) * 100)
        return "\(percent)%"
    }
}
