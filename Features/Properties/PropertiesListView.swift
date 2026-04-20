import SwiftUI

struct PropertiesListView: View {

    @Bindable var store: AppStore

    @State private var selectedProperty: Property? = nil
    @State private var propertyToEdit: Property? = nil
    @State private var showAddProperty = false
    @State private var pendingDeleteProperty: Property? = nil

    private let pagePadding: CGFloat = 16

    private var sortedProperties: [Property] {
        store.properties.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if sortedProperties.isEmpty {
                    emptyState
                } else {
                    propertyCards
                }
            }
            .padding(.horizontal, pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Properties")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddProperty = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add property")
                .accessibilityHint("Opens the form to add a new property")
            }
        }
        .navigationDestination(item: $selectedProperty) { property in
            PropertyDetailView(
                store: store,
                propertyID: property.id
            )
        }
        .sheet(isPresented: $showAddProperty) {
            AddEditPropertyView(store: store)
        }
        .sheet(item: $propertyToEdit) { property in
            AddEditPropertyView(store: store, property: property)
        }
        .confirmationDialog(
            "Delete property?",
            isPresented: Binding(
                get: { pendingDeleteProperty != nil },
                set: { if !$0 { pendingDeleteProperty = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let property = pendingDeleteProperty else { return }

                withAnimation(.easeInOut(duration: 0.22)) {
                    store.deleteProperty(property.id)
                }

                pendingDeleteProperty = nil
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteProperty = nil
            }
        } message: {
            if let property = pendingDeleteProperty {
                Text("This will remove \(property.name) and all tenants, bills, payment history, and linked records.")
            }
        }
    }
}

private extension PropertiesListView {

    var propertyCards: some View {
        VStack(spacing: 12) {
            ForEach(sortedProperties) { property in
                Button {
                    selectedProperty = property
                } label: {
                    PropertyListCardLarge(
                        property: property,
                        tenantCount: store.tenantCount(for: property),
                        monthlyIncome: store.monthlyIncome(for: property)
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        propertyToEdit = property
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button(role: .destructive) {
                        pendingDeleteProperty = property
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        propertyToEdit = property
                    } label: {
                        Label("Edit Property", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        pendingDeleteProperty = property
                    } label: {
                        Label("Delete Property", systemImage: "trash")
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityHint("Double tap to open property details. Swipe left for edit and delete actions.")
            }
        }
    }

    var emptyState: some View {
        Button {
            showAddProperty = true
        } label: {
            VStack(spacing: 18) {
                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 88, height: 88)

                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(.blue)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Add your first property")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Create a property to start managing tenants, bills, reminders, and payment history.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                HStack(spacing: 10) {
                    Text("Add Property")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(uiColor: .tertiarySystemBackground))
                .clipShape(Capsule())

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(24)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add your first property")
        .accessibilityHint("Opens the form to add a property")
    }
}
