import SwiftUI
import PhotosUI

struct AddTenantView: View {

    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let preselectedPropertyID: Property.ID?
    let tenantToEdit: Tenant?

    @State private var name: String
    @State private var monthlyRent: Decimal
    @State private var selectedPropertyID: Property.ID?
    @State private var selectedRoomID: Room.ID?
    @State private var nextDueDate: Date
    @State private var note: String
    @State private var imageData: Data?
    @State private var monthlyRentText: String

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var showCameraPicker = false

    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    private var isEditing: Bool { tenantToEdit != nil }

    init(
        store: AppStore,
        preselectedPropertyID: Property.ID? = nil,
        tenant: Tenant? = nil
    ) {
        self.store = store
        self.preselectedPropertyID = preselectedPropertyID
        self.tenantToEdit = tenant

        _name = State(initialValue: tenant?.name ?? "")
        _monthlyRent = State(initialValue: tenant?.monthlyRent ?? 0)
        _selectedPropertyID = State(initialValue: tenant?.propertyID ?? preselectedPropertyID)
        _selectedRoomID = State(initialValue: tenant?.roomID)
        _nextDueDate = State(initialValue: tenant?.nextDueDate ?? Date())
        _note = State(initialValue: tenant?.note ?? "")
        _imageData = State(initialValue: tenant?.imageData)
        _monthlyRentText = State(initialValue: tenant.map { NSDecimalNumber(decimal: $0.monthlyRent).stringValue } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                tenantSection
                propertySection
                photoSection
                notesSection
            }
            .navigationTitle(isEditing ? "Edit Tenant" : "Add Tenant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTenant()
                    }
                    .disabled(isSaveDisabled)
                    .accessibilityHint(isEditing ? "Saves tenant changes" : "Adds this tenant")
                }
            }
            .alert(isEditing ? "Unable to Save Tenant" : "Unable to Add Tenant", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onChange(of: selectedPropertyID) { _, _ in
                selectedRoomID = nil
            }
            .onChange(of: pickerItem) { _, newItem in
                loadImage(from: newItem)
            }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            AppUIKitImagePicker(sourceType: .camera) { data in
                if let data {
                    imageData = data
                }
            }
            .ignoresSafeArea()
        }
    }
}

private extension AddTenantView {

    var tenantSection: some View {
        Section {
            TextField("Full name", text: $name)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Tenant full name")

            TextField("Payment amount", text: $monthlyRentText)
                .keyboardType(.decimalPad)
                .accessibilityLabel("Monthly rent")
                .onChange(of: monthlyRentText) { _, newValue in
                    let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                    monthlyRent = Decimal(string: normalized) ?? 0
                }

            DatePicker(
                "Next payment date",
                selection: $nextDueDate,
                in: Date()...,
                displayedComponents: .date
            )
            .accessibilityHint("Sets the next scheduled payment date")
        } header: {
            Text("Tenant")
        }
    }

    var propertySection: some View {
        Section {
            Picker("Property", selection: $selectedPropertyID) {
                Text("Select property")
                    .tag(nil as Property.ID?)

                ForEach(store.properties) { property in
                    Text(property.name)
                        .tag(property.id as Property.ID?)
                }
            }
            .disabled(preselectedPropertyID != nil)
            .accessibilityHint(
                preselectedPropertyID != nil
                ? "This property was preselected"
                : "Choose the property for this tenant"
            )

            if let selectedProperty {
                if selectedProperty.rentalMode == .wholeProperty {
                    Text("This tenant will rent the whole property.")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                } else {
                    Picker("Room", selection: $selectedRoomID) {
                        Text("Select room")
                            .tag(nil as Room.ID?)

                        ForEach(availableRooms(for: selectedProperty)) { room in
                            Text(room.name)
                                .tag(room.id as Room.ID?)
                        }
                    }
                    .accessibilityHint("Choose a room for this tenant")
                }
            }
        } header: {
            Text("Property")
        }
    }

    var photoSection: some View {
        Section {
            HStack(spacing: 12) {
                AvatarView(
                    name: name.isEmpty ? "Tenant" : name,
                    imageName: tenantToEdit?.imageName,
                    imageData: imageData,
                    size: CGSize(width: 76, height: 76),
                    cornerRadius: 22
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 10) {

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(
                            imageData == nil ? "Choose from library" : "Change photo",
                            systemImage: "photo.on.rectangle"
                        )
                    }

                    if AppImageSource.camera.isAvailable {
                        Button {
                            showCameraPicker = true
                        } label: {
                            HStack {
                                Spacer()

                                Image(systemName: "camera")
                                Text("Take photo")

                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
        } header: {
            Text("Photo")
        }
    }

    var notesSection: some View {
        Section {
            TextField("Optional notes", text: $note, axis: .vertical)
                .lineLimit(3...5)
                .accessibilityLabel("Tenant notes")
        } header: {
            Text("Notes")
        }
    }

    var selectedProperty: Property? {
        guard let selectedPropertyID else { return nil }
        return store.properties.first(where: { $0.id == selectedPropertyID })
    }

    var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        monthlyRent <= 0 ||
        selectedPropertyID == nil
    }

    func availableRooms(for property: Property) -> [Room] {
        property.rooms.filter { room in
            !store.tenants.contains {
                $0.propertyID == property.id &&
                $0.roomID == room.id &&
                $0.isActive &&
                $0.id != tenantToEdit?.id
            }
        }
    }

    func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    imageData = data
                }
            }
        }
    }

    func saveTenant() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            presentValidation("Please enter the tenant name.")
            return
        }

        guard monthlyRent > 0 else {
            presentValidation("Please enter a valid monthly rent.")
            return
        }

        guard let property = selectedProperty else {
            presentValidation("Please select a property.")
            return
        }

        let roomID: Room.ID?

        switch property.rentalMode {
        case .wholeProperty:
            roomID = nil

            if let editingTenant = tenantToEdit {
                let conflictingTenant = store.tenants.contains {
                    $0.propertyID == property.id &&
                    $0.roomID == nil &&
                    $0.isActive &&
                    $0.id != editingTenant.id
                }

                guard !conflictingTenant else {
                    presentValidation("This property already has an active tenant renting the whole property.")
                    return
                }
            } else {
                guard store.canAddTenant(to: property, roomID: nil) else {
                    presentValidation("This property already has an active tenant renting the whole property.")
                    return
                }
            }

        case .byRooms:
            guard let selectedRoomID else {
                presentValidation("Please select a room for this tenant.")
                return
            }

            roomID = selectedRoomID

            if let editingTenant = tenantToEdit {
                let conflictingTenant = store.tenants.contains {
                    $0.propertyID == property.id &&
                    $0.roomID == selectedRoomID &&
                    $0.isActive &&
                    $0.id != editingTenant.id
                }

                guard !conflictingTenant else {
                    presentValidation("This room is already occupied by another active tenant.")
                    return
                }
            } else {
                guard store.canAddTenant(to: property, roomID: selectedRoomID) else {
                    presentValidation("This room is already occupied by another active tenant.")
                    return
                }
            }
        }

        if var existing = tenantToEdit {
            existing.propertyID = property.id
            existing.roomID = roomID
            existing.name = trimmedName
            existing.imageData = imageData
            existing.monthlyRent = monthlyRent
            existing.nextDueDate = nextDueDate
            existing.scheduledDayOfMonth = Calendar.current.component(.day, from: nextDueDate)
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote

            store.updateTenant(existing)
        } else {
            let newTenant = Tenant(
                propertyID: property.id,
                roomID: roomID,
                name: trimmedName,
                imageName: nil,
                imageData: imageData,
                monthlyRent: monthlyRent,
                nextDueDate: nextDueDate,
                moveInDate: .now,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )

            store.addTenant(newTenant)
        }

        dismiss()
    }

    func presentValidation(_ message: String) {
        validationMessage = message
        showValidationAlert = true
    }
}
