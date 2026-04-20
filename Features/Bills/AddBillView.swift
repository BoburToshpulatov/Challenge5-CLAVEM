import SwiftUI
import PhotosUI

struct AddBillView: View {

    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let propertyID: Property.ID

    @State private var selectedType: BillType = .water
    @State private var title: String = ""
    @State private var totalAmount: Decimal = 0
    @State private var billDate: Date = .now
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = .now
    @State private var includeInTenantPayments: Bool = true
    @State private var note: String = ""

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var showCameraPicker = false

    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    private var property: Property? {
        store.properties.first(where: { $0.id == propertyID })
    }

    private var activeTenants: [Tenant] {
        guard let property else { return [] }
        return store.tenants(for: property)
    }

    private var splitAmountPerTenant: Decimal {
        let count = activeTenants.count
        guard count > 0 else { return totalAmount }
        return totalAmount / Decimal(count)
    }

    var body: some View {
        NavigationStack {
            Form {
                billSection
                datesSection
                photoSection
                paymentHandlingSection
                splitPreviewSection
                notesSection
                propertySection
            }
            .navigationTitle("Add Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelToolbar
                saveToolbar
            }
            .alert("Unable to Add Bill", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onChange(of: selectedType) { _, newType in
                if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    title = newType.title
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                loadImage(from: newItem)
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            AppUIKitImagePicker(sourceType: .camera) { data in
                if let data {
                    photoData = data
                }
            }
        }
    }
}

private extension AddBillView {

    var billSection: some View {
        Section {
            Picker("Bill type", selection: $selectedType) {
                ForEach(BillType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .accessibilityHint("Choose the type of bill")

            TextField("Title", text: $title)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Bill title")

            TextField("Total amount", value: $totalAmount, format: .number)
                .keyboardType(.decimalPad)
                .accessibilityLabel("Total bill amount")
        } header: {
            Text("Bill")
        }
    }

    var datesSection: some View {
        Section {
            DatePicker(
                "Bill date",
                selection: $billDate,
                displayedComponents: .date
            )

            Toggle("Add due date", isOn: $hasDueDate)

            if hasDueDate {
                DatePicker(
                    "Due date",
                    selection: $dueDate,
                    in: billDate...,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("Dates")
        }
    }

    var photoSection: some View {
        Section {
            HStack(spacing: 12) {
                AvatarView(
                    name: title.isEmpty ? selectedType.title : title,
                    imageName: nil,
                    imageData: photoData,
                    size: CGSize(width: 76, height: 76),
                    cornerRadius: 22
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 10) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(
                            photoData == nil ? "Choose from library" : "Change from library",
                            systemImage: "photo.on.rectangle"
                        )
                    }

                    if AppImageSource.camera.isAvailable {
                        Button {
                            showCameraPicker = true
                        } label: {
                            Label("Take photo", systemImage: "camera")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Spacer()
            }
        } header: {
            Text("Photo")
        }
    }

    var paymentHandlingSection: some View {
        Section {
            Toggle("Include in tenant payments", isOn: $includeInTenantPayments)
                .accessibilityHint("When enabled, this bill will be split and added to active tenant payment amounts")

            if let property {
                Text(
                    property.billsEnabled
                    ? "Bill splitting is enabled for this property."
                    : "Bill splitting is turned off for this property."
                )
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
            }
        } header: {
            Text("Payment Handling")
        }
    }

    @ViewBuilder
    var splitPreviewSection: some View {
        if includeInTenantPayments, let property {
            Section {
                if property.billsEnabled == false {
                    Text("This property has bill splitting turned off. The bill will be saved, but it will not be added to tenant payments.")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                } else if activeTenants.isEmpty {
                    Text("There are no active tenants in this property yet, so no split will be created.")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                } else {
                    HStack {
                        Text("Split across")
                        Spacer()
                        Text("\(activeTenants.count) tenants")
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }

                    HStack {
                        Text("Per tenant")
                        Spacer()
                        Text(splitAmountPerTenant, format: .currency(code: "EUR"))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            } header: {
                Text("Split Preview")
            }
        }
    }

    var notesSection: some View {
        Section {
            TextField("Optional notes", text: $note, axis: .vertical)
                .lineLimit(3...5)
                .accessibilityLabel("Bill notes")
        } header: {
            Text("Notes")
        }
    }

    @ViewBuilder
    var propertySection: some View {
        if let property {
            Section {
                HStack {
                    Text("Property")
                    Spacer()
                    Text(property.name)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
            } header: {
                Text("Property")
            }
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
                saveBill()
            }
            .disabled(isSaveDisabled)
            .accessibilityHint("Saves this bill")
        }
    }

    var isSaveDisabled: Bool {
        totalAmount <= 0 || property == nil
    }

    func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    photoData = data
                }
            }
        }
    }

    func saveBill() {
        guard let property else {
            presentValidation("Property not found.")
            return
        }

        guard totalAmount > 0 else {
            presentValidation("Please enter a valid bill amount.")
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? selectedType.title : trimmedTitle

        let bill = Bill(
            propertyID: property.id,
            type: selectedType,
            title: finalTitle,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            totalAmount: totalAmount,
            billDate: billDate,
            dueDate: hasDueDate ? dueDate : nil,
            photoData: photoData,
            isIncludedInTenantPayments: includeInTenantPayments
        )

        store.addBill(bill)
        dismiss()
    }

    func presentValidation(_ message: String) {
        validationMessage = message
        showValidationAlert = true
    }
}
