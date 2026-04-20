import SwiftUI

struct PropertyDetailView: View {

    @Bindable var store: AppStore
    let propertyID: Property.ID

    private let pagePadding: CGFloat = 16

    @State private var showAddTenant = false
    @State private var showAddBill = false
    @State private var propertyToEdit: Property? = nil

    @State private var isEditingNotes = false
    @State private var draftNote = ""

    private var property: Property? {
        store.properties.first { $0.id == propertyID }
    }

    var body: some View {
        if let property = property {
            let activeTenants = store.tenants(for: property)
            let monthlyIncome = store.monthlyIncome(for: property)
            let propertyBills = store.bills(for: property)
            let occupancy = store.occupancyHistory
                .filter { $0.propertyID == property.id }
                .sorted { $0.moveInDate > $1.moveInDate }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    propertyImage(property)

                    propertyHeader(property)

                    statsSection(
                        property: property,
                        tenants: activeTenants,
                        income: monthlyIncome
                    )

                    propertyMetaSection(property)

                    occupancyOverviewSection(property, tenants: activeTenants)

                    tenantsSection(property, tenants: activeTenants)

                    billsSection(property, bills: propertyBills, tenants: activeTenants)

                    occupancySection(occupancy)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Property")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        propertyToEdit = property
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit property")
                }
            }
            .sheet(isPresented: $showAddTenant) {
                AddTenantView(
                    store: store,
                    preselectedPropertyID: property.id
                )
            }
            .sheet(isPresented: $showAddBill) {
                AddBillView(
                    store: store,
                    propertyID: property.id
                )
            }
            .sheet(item: $propertyToEdit) { property in
                AddEditPropertyView(
                    store: store,
                    property: property
                )
            }
            .sheet(isPresented: $isEditingNotes) {
                editNotesSheet
            }
        } else {
            ContentUnavailableView(
                "Property not found",
                systemImage: "house"
            )
        }
    }
}

private extension PropertyDetailView {

    func propertyImage(_ property: Property) -> some View {
        AvatarView(
            name: property.name,
            imageName: property.imageName,
            imageData: property.imageData,
            size: CGSize(
                width: UIScreen.main.bounds.width - (pagePadding * 2),
                height: 240
            ),
            cornerRadius: 26
        )
        .padding(.horizontal, pagePadding)
        .padding(.top, 10)
        .accessibilityLabel("\(property.name) photo")
    }

    func propertyHeader(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(property.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.leading)

            Text("\(property.addressLine), \(property.city)")
                .foregroundStyle(Color.primary.opacity(0.72))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, pagePadding)
    }

    func statsSection(
        property: Property,
        tenants: [Tenant],
        income: Decimal
    ) -> some View {
        HStack(spacing: 12) {
            StatPill(
                title: "Tenants",
                value: "\(tenants.count)"
            )

            StatPill(
                title: "Monthly",
                value: income,
                isCurrency: true
            )

            StatPill(
                title: "Occupancy",
                value: occupancyValue(for: property, tenants: tenants)
            )
        }
        .padding(.horizontal, pagePadding)
    }

    func propertyMetaSection(_ property: Property) -> some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {

                HStack(spacing: 8) {
                    metaBadge(
                        title: property.rentalMode == .wholeProperty ? "Whole property" : "By rooms",
                        tint: .secondary
                    )

                    metaBadge(
                        title: property.billsEnabled ? "Bills enabled" : "Bills off",
                        tint: property.billsEnabled ? .indigo : .secondary
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            draftNote = property.note ?? ""
                            isEditingNotes = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit property notes")
                    }

                    if let note = property.note, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("No notes added yet")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.72))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func occupancyOverviewSection(_ property: Property, tenants: [Tenant]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(property.rentalMode == .wholeProperty ? "Current occupancy" : "Rooms")
                .font(.title3.bold())

            if property.rentalMode == .wholeProperty {
                wholePropertyOccupancyCard(property, tenants: tenants)
            } else {
                roomsSection(property, tenants: tenants)
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func wholePropertyOccupancyCard(_ property: Property, tenants: [Tenant]) -> some View {
        let tenant = tenants.first

        return sectionCard {
            if let tenant = tenant {
                NavigationLink {
                    TenantDetailView(
                        store: store,
                        tenantID: tenant.id
                    )
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(
                            name: tenant.name,
                            imageName: tenant.imageName,
                            imageData: tenant.imageData,
                            size: CGSize(width: 48, height: 48),
                            cornerRadius: 16
                        )
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tenant.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(store.status(for: tenant).rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(store.currentAmountDue(for: tenant), format: .currency(code: "EUR"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text((tenant.activeDelay?.newDueDate ?? tenant.nextDueDate).formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No active tenant")
                        .font(.headline)

                    Text("This property is currently vacant.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func roomsSection(_ property: Property, tenants: [Tenant]) -> some View {
        Group {
            if property.rooms.isEmpty {
                sectionCard {
                    Text("No rooms added yet.")
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(property.rooms) { room in
                        let roomTenant = tenants.first { $0.roomID == room.id }

                        sectionCard {
                            if let roomTenant = roomTenant {
                                NavigationLink {
                                    TenantDetailView(
                                        store: store,
                                        tenantID: roomTenant.id
                                    )
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(room.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

                                            Text(roomTenant.name)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.primary.opacity(0.72))

                                            if let note = room.note, !note.isEmpty {
                                                Text(note)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.primary.opacity(0.72))
                                            }
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(roomTenant.monthlyRent, format: .currency(code: "EUR"))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)

                                            Text("Occupied")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            } else {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(room.name)
                                            .font(.headline)

                                        if let note = room.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(Color.primary.opacity(0.72))
                                        }
                                    }

                                    Spacer()

                                    Text("Vacant")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    func tenantsSection(_ property: Property, tenants: [Tenant]) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Tenants")
                    .font(.title3.bold())

                Spacer()

                Button {
                    showAddTenant = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
                .accessibilityLabel("Add tenant")
                .accessibilityHint("Adds a tenant to this property")
            }

            if tenants.isEmpty {
                sectionCard {
                    Text("No tenants yet")
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(tenants) { tenant in
                        NavigationLink {
                            TenantDetailView(
                                store: store,
                                tenantID: tenant.id
                            )
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(
                                    name: tenant.name,
                                    imageName: tenant.imageName,
                                    imageData: tenant.imageData,
                                    size: CGSize(width: 44, height: 44),
                                    cornerRadius: 14
                                )
                                .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tenant.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    if let roomName = store.roomName(for: tenant) {
                                        Text(roomName)
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))
                                    } else {
                                        Text("Whole property tenant")
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(store.currentAmountDue(for: tenant), format: .currency(code: "EUR"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    Text(store.status(for: tenant).rawValue.capitalized)
                                        .font(.caption2)
                                        .foregroundStyle(Color.primary.opacity(0.72))
                                }
                            }
                            .padding(14)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens tenant details")
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func billsSection(_ property: Property, bills: [Bill], tenants: [Tenant]) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Bills & split")
                    .font(.title3.bold())

                Spacer()

                if property.billsEnabled {
                    Button {
                        showAddBill = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel("Add bill")
                    .accessibilityHint("Adds a bill for this property")
                }
            }

            if property.billsEnabled == false {
                sectionCard {
                    Text("Bill splitting is turned off for this property.")
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if bills.isEmpty {
                sectionCard {
                    Text("No bills added yet")
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(bills.prefix(5))) { bill in
                        let billShares = store.billShares.filter { $0.billID == bill.id }
                        let splitCount = billShares.count
                        let splitAmount = splitCount > 0
                        ? bill.totalAmount / Decimal(splitCount)
                        : bill.totalAmount

                        sectionCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bill.title)
                                            .font(.headline)

                                        Text(bill.type.title)
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))

                                        if let note = bill.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(Color.primary.opacity(0.72))
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(bill.totalAmount, format: .currency(code: "EUR"))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)

                                        Text(bill.billDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))
                                    }
                                }

                                Divider()

                                if splitCount > 0 {
                                    HStack {
                                        Text("Split across")
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))

                                        Spacer()

                                        Text("\(splitCount) tenants")
                                            .font(.caption.weight(.semibold))
                                    }

                                    HStack {
                                        Text("Per tenant")
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))

                                        Spacer()

                                        Text(splitAmount, format: .currency(code: "EUR"))
                                            .font(.caption.weight(.semibold))
                                    }
                                } else {
                                    Text("This bill is not currently assigned to active tenant payments.")
                                        .font(.caption)
                                        .foregroundStyle(Color.primary.opacity(0.72))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func occupancySection(_ occupancy: [OccupancyRecord]) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Occupancy history")
                .font(.title3.bold())

            if occupancy.isEmpty {
                sectionCard {
                    Text("No previous occupancy records")
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(occupancy.prefix(5))) { record in
                        sectionCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.tenantNameSnapshot)
                                        .font(.headline)

                                    if let moveOutDate = record.moveOutDate {
                                        Text("\(record.moveInDate.formatted(date: .abbreviated, time: .omitted)) – \(moveOutDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))
                                    } else {
                                        Text("From \(record.moveInDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(Color.primary.opacity(0.72))
                                    }
                                }

                                Spacer()

                                Text(record.finalMonthlyRent, format: .currency(code: "EUR"))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, pagePadding)
    }

    func occupancyValue(for property: Property, tenants: [Tenant]) -> String {
        switch property.rentalMode {
        case .wholeProperty:
            return tenants.isEmpty ? "0 / 1" : "1 / 1"
        case .byRooms:
            return "\(tenants.count) / \(property.rooms.count)"
        }
    }

    var editNotesSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $draftNote)
                        .frame(minHeight: 180)
                }
            }
            .navigationTitle("Edit Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditingNotes = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePropertyNote()
                    }
                }
            }
        }
    }

    func savePropertyNote() {
        guard var property = property else {
            isEditingNotes = false
            return
        }

        let trimmed = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        property.note = trimmed.isEmpty ? nil : trimmed
        store.updateProperty(property)
        isEditingNotes = false
    }

    func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }

    func metaBadge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}
