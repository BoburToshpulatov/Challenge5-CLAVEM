import SwiftUI
import PhotosUI

struct AddEditPropertyView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let propertyToEdit: Property?

    @State private var name: String
    @State private var addressLine: String
    @State private var city: String

    @State private var rooms: [Room]
    @State private var newRoomName: String = ""

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil

    private var isEditing: Bool { propertyToEdit != nil }

    init(store: AppStore, property: Property? = nil) {
        self.store = store
        self.propertyToEdit = property

        _name = State(initialValue: property?.name ?? "")
        _addressLine = State(initialValue: property?.addressLine ?? "")
        _city = State(initialValue: property?.city ?? "")
        _rooms = State(initialValue: property?.rooms ?? [])
        _imageData = State(initialValue: property?.imageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Name", text: $name)
                    TextField("Address", text: $addressLine)
                    TextField("City", text: $city)
                }

                Section("Photo") {
                    HStack(spacing: 12) {
                        AvatarView(
                            name: name.isEmpty ? "Property" : name,
                            imageName: propertyToEdit?.imageName,
                            imageData: imageData,
                            size: CGSize(width: 72, height: 72),
                            cornerRadius: 22
                        )

                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Text(imageData == nil ? "Upload photo" : "Change photo")
                        }
                    }
                }

                Section {
                    Toggle(
                        rooms.isEmpty ? "Rented as whole property" : "Rooms enabled",
                        isOn: Binding(
                            get: { !rooms.isEmpty },
                            set: { enabled in
                                if !enabled { rooms.removeAll() }
                                if enabled && rooms.isEmpty {
                                    rooms = [Room(name: "Room 1")]
                                }
                            }
                        )
                    )
                } footer: {
                    Text("If rooms are off, tenants rent the entire property.")
                }

                if !rooms.isEmpty {
                    Section("Rooms") {
                        ForEach(rooms) { room in
                            Text(room.name)
                        }
                        .onDelete { indexSet in
                            rooms.remove(atOffsets: indexSet)
                        }

                        HStack {
                            TextField("New room", text: $newRoomName)
                            Button("Add") {
                                let trimmed = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                rooms.append(Room(name: trimmed))
                                newRoomName = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Property" : "Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              addressLine.trimmingCharacters(in: .whitespaces).isEmpty ||
                              city.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run { self.imageData = data }
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)

        if var existing = propertyToEdit {
            existing.name = trimmedName
            existing.addressLine = trimmedAddress
            existing.city = trimmedCity
            existing.imageData = imageData
            existing.rooms = rooms
            store.updateProperty(existing)
        } else {
            let new = Property(
                name: trimmedName,
                addressLine: trimmedAddress,
                city: trimmedCity,
                imageData: imageData,
                rooms: rooms
            )
            store.addProperty(new)
        }
    }
}
