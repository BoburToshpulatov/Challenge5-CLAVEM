import SwiftUI
import PhotosUI

struct AddEditPropertyView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let propertyToEdit: Property?

    @State private var name: String
    @State private var addressLine: String
    @State private var city: String
    @State private var rentalMode: RentalMode
    @State private var billsEnabled: Bool
    @State private var note: String

    @State private var rooms: [Room]
    @State private var newRoomName: String = ""

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil

    @State private var showCameraPicker = false

    private var isEditing: Bool { propertyToEdit != nil }

    init(store: AppStore, property: Property? = nil) {
        self.store = store
        self.propertyToEdit = property

        _name = State(initialValue: property?.name ?? "")
        _addressLine = State(initialValue: property?.addressLine ?? "")
        _city = State(initialValue: property?.city ?? "")
        _rentalMode = State(initialValue: property?.rentalMode ?? .wholeProperty)
        _billsEnabled = State(initialValue: property?.billsEnabled ?? false)
        _note = State(initialValue: property?.note ?? "")
        _rooms = State(initialValue: property?.rooms ?? [])
        _imageData = State(initialValue: property?.imageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                propertySection
                photoSection
                rentalSetupSection

                if rentalMode == .byRooms {
                    roomsSection
                }

                notesSection
            }
            .navigationTitle(isEditing ? "Edit Property" : "Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelToolbar
                saveToolbar
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            loadImage(from: newItem)
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

private extension AddEditPropertyView {

    var propertySection: some View {
        Section {
            TextField("Property name", text: $name)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Property name")

            TextField("Address", text: $addressLine)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Address")

            TextField("City", text: $city)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("City")
        } header: {
            Text("Property")
        }
    }

    var photoSection: some View {
        Section {
            HStack(spacing: 14) {

                AvatarView(
                    name: name.isEmpty ? "Property" : name,
                    imageName: propertyToEdit?.imageName,
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
            }
        } header: {
            Text("Photo")
        }
    }

    var rentalSetupSection: some View {
        Section {
            Picker("Rental mode", selection: $rentalMode) {
                Text("Whole property").tag(RentalMode.wholeProperty)
                Text("By rooms").tag(RentalMode.byRooms)
            }
            .accessibilityHint("Choose whether the property is rented as a whole or by individual rooms")
            .onChange(of: rentalMode) { _, newValue in
                if newValue == .wholeProperty {
                    rooms.removeAll()
                } else if rooms.isEmpty {
                    rooms = [Room(name: "Room 1")]
                }
            }

            Toggle("Enable bill splitting", isOn: $billsEnabled)
                .accessibilityHint("Allows bills to be added and split among active tenants")
        } header: {
            Text("Rental Setup")
        }
    }

    var roomsSection: some View {
        Section {
            if rooms.isEmpty {
                Text("No rooms added yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rooms) { room in
                    Text(room.name)
                }
                .onDelete { indexSet in
                    rooms.remove(atOffsets: indexSet)
                }
            }

            HStack {
                TextField("New room", text: $newRoomName)
                    .accessibilityLabel("New room name")

                Button("Add") {
                    addRoom()
                }
                .disabled(newRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text("Rooms")
        } footer: {
            Text("Each active tenant can be assigned to a room when the property is rented by rooms.")
        }
    }

    var notesSection: some View {
        Section {
            TextField("Optional notes", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .accessibilityLabel("Property notes")
        } header: {
            Text("Notes")
        }
    }

    var cancelToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
    }

    var saveToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                save()
                dismiss()
            }
            .disabled(isSaveDisabled)
            .accessibilityHint("Saves this property")
        }
    }

    var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func addRoom() {
        let trimmed = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        rooms.append(Room(name: trimmed))
        newRoomName = ""
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

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let finalRooms: [Room] = rentalMode == .wholeProperty ? [] : rooms

        if var existing = propertyToEdit {
            existing.name = trimmedName
            existing.addressLine = trimmedAddress
            existing.city = trimmedCity
            existing.rentalMode = rentalMode
            existing.billsEnabled = billsEnabled
            existing.imageData = imageData
            existing.rooms = finalRooms
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote

            store.updateProperty(existing)
        } else {
            let newProperty = Property(
                name: trimmedName,
                addressLine: trimmedAddress,
                city: trimmedCity,
                rentalMode: rentalMode,
                billsEnabled: billsEnabled,
                imageName: nil,
                imageData: imageData,
                rooms: finalRooms,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )

            store.addProperty(newProperty)
        }
    }
}
