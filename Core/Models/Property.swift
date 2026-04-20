import Foundation

// MARK: - Property Rental Mode

enum RentalMode: String, Codable, Hashable, CaseIterable {
    case wholeProperty
    case byRooms
}

// MARK: - Bill Type

enum BillType: String, Codable, Hashable, CaseIterable, Identifiable {
    case water
    case gas
    case electricity
    case internet
    case maintenance
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .water: return "Water"
        case .gas: return "Gas"
        case .electricity: return "Electricity"
        case .internet: return "Internet"
        case .maintenance: return "Maintenance"
        case .other: return "Other"
        }
    }
}

// MARK: - Room

struct Room: Identifiable, Hashable {
    let id: UUID
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

// MARK: - Property

struct Property: Identifiable, Hashable {
    let id: UUID

    var name: String
    var addressLine: String
    var city: String

    var rentalMode: RentalMode
    var billsEnabled: Bool

    var imageName: String?
    var imageData: Data?

    var rooms: [Room]
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        addressLine: String,
        city: String,
        rentalMode: RentalMode = .wholeProperty,
        billsEnabled: Bool = false,
        imageName: String? = nil,
        imageData: Data? = nil,
        rooms: [Room] = [],
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.addressLine = addressLine
        self.city = city
        self.rentalMode = rentalMode
        self.billsEnabled = billsEnabled
        self.imageName = imageName
        self.imageData = imageData
        self.note = note

        switch rentalMode {
        case .wholeProperty:
            self.rooms = []
        case .byRooms:
            self.rooms = rooms
        }
    }
}

// MARK: - Tenant

struct Tenant: Identifiable, Hashable {
    let id: UUID

    var propertyID: Property.ID
    var roomID: Room.ID?   // nil = whole-property tenant

    var name: String
    var imageName: String?
    var imageData: Data?

    var monthlyRent: Decimal
    var scheduledDayOfMonth: Int
    var nextDueDate: Date
    var activeDelay: PaymentDelay?

    var moveInDate: Date
    var moveOutDate: Date?
    var isActive: Bool
    var note: String?

    init(
        id: UUID = UUID(),
        propertyID: Property.ID,
        roomID: Room.ID? = nil,
        name: String,
        imageName: String? = nil,
        imageData: Data? = nil,
        monthlyRent: Decimal,
        scheduledDayOfMonth: Int? = nil,
        nextDueDate: Date,
        activeDelay: PaymentDelay? = nil,
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
        self.nextDueDate = nextDueDate
        self.scheduledDayOfMonth = scheduledDayOfMonth ?? Calendar.current.component(.day, from: nextDueDate)
        self.activeDelay = activeDelay
        self.moveInDate = moveInDate
        self.moveOutDate = moveOutDate
        self.isActive = isActive
        self.note = note
    }
}

// MARK: - Temporary Delay

struct PaymentDelay: Hashable {
    var originalDueDate: Date
    var newDueDate: Date
    var reason: String?
}

// MARK: - Property Bill

struct Bill: Identifiable, Hashable {
    let id: UUID

    var propertyID: Property.ID
    var type: BillType
    var title: String
    var note: String?

    var totalAmount: Decimal
    var billDate: Date
    var dueDate: Date?

    var photoData: Data?

    /// Whether this bill should be included in tenant payment reminders
    var isIncludedInTenantPayments: Bool

    init(
        id: UUID = UUID(),
        propertyID: Property.ID,
        type: BillType,
        title: String? = nil,
        note: String? = nil,
        totalAmount: Decimal,
        billDate: Date = .now,
        dueDate: Date? = nil,
        photoData: Data? = nil,
        isIncludedInTenantPayments: Bool = true
    ) {
        self.id = id
        self.propertyID = propertyID
        self.type = type
        self.title = title ?? type.title
        self.note = note
        self.totalAmount = totalAmount
        self.billDate = billDate
        self.dueDate = dueDate
        self.photoData = photoData
        self.isIncludedInTenantPayments = isIncludedInTenantPayments
    }
}

// MARK: - Bill Share

struct BillShare: Identifiable, Hashable {
    let id: UUID

    var billID: Bill.ID
    var tenantID: Tenant.ID
    var amount: Decimal

    /// Month this share belongs to
    var billingMonth: Date

    /// Whether this share is still unpaid
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        billID: Bill.ID,
        tenantID: Tenant.ID,
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

// MARK: - Occupancy History

struct OccupancyRecord: Identifiable, Hashable {
    let id: UUID

    var propertyID: Property.ID
    var roomID: Room.ID?
    var tenantNameSnapshot: String

    var moveInDate: Date
    var moveOutDate: Date?

    var finalMonthlyRent: Decimal
    var note: String?

    init(
        id: UUID = UUID(),
        propertyID: Property.ID,
        roomID: Room.ID? = nil,
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

// MARK: - Payment Record

struct PaymentRecord: Identifiable, Hashable {
    let id: UUID

    var tenantID: Tenant.ID
    var propertyID: Property.ID

    var dueDate: Date
    var paidDate: Date?

    var baseRentAmount: Decimal
    var billPortionAmount: Decimal
    var totalAmount: Decimal

    var note: String?

    var isPaid: Bool { paidDate != nil }

    init(
        id: UUID = UUID(),
        tenantID: Tenant.ID,
        propertyID: Property.ID,
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

// MARK: - Upcoming Payment UI Model

struct UpcomingPayment: Identifiable, Hashable {
    let id: UUID

    var tenantID: Tenant.ID
    var tenantName: String
    var tenantImageName: String?
    var propertyName: String

    var dueDate: Date

    var baseRentAmount: Decimal
    var billPortionAmount: Decimal
    var amount: Decimal

    var isDelayed: Bool

    init(
        id: UUID = UUID(),
        tenantID: Tenant.ID,
        tenantName: String,
        tenantImageName: String?,
        propertyName: String,
        dueDate: Date,
        baseRentAmount: Decimal,
        billPortionAmount: Decimal = 0,
        amount: Decimal,
        isDelayed: Bool
    ) {
        self.id = id
        self.tenantID = tenantID
        self.tenantName = tenantName
        self.tenantImageName = tenantImageName
        self.propertyName = propertyName
        self.dueDate = dueDate
        self.baseRentAmount = baseRentAmount
        self.billPortionAmount = billPortionAmount
        self.amount = amount
        self.isDelayed = isDelayed

    }
}
