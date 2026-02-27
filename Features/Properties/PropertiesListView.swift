import SwiftUI

struct PropertiesListView: View {
    @Bindable var store: AppStore

    @State private var showAdd = false
    @State private var editTarget: Property? = nil
    @State private var deleteTarget: Property? = nil
    @State private var selectedProperty: Property? = nil

    var body: some View {
        let s = store

        List {
            ForEach(s.properties) { property in
                Button {
                    selectedProperty = property
                } label: {
                    PropertyListCardLarge(
                        property: property,
                        tenantCount: s.tenantCount(for: property),
                        monthlyIncome: s.monthlyIncome(for: property)
                    )
                }
                .buttonStyle(.plain) // keeps card look
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)) // ✅ smaller gaps

                // ✅ Leading: Edit (good practice)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        editTarget = property
                        showAdd = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }

                // ✅ Trailing: Delete (native + safer: no full swipe)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTarget = property
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if s.properties.isEmpty {
                ContentUnavailableView("No properties yet", systemImage: "building.2")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Properties")

        // ✅ Push to detail without chevron
        .navigationDestination(item: $selectedProperty) { property in
            PropertyDetailView(store: s, propertyID: property.id)
        }

        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editTarget = nil
                    showAdd = true
                } label: { Image(systemName: "plus") }
            }
        }

        // ✅ Modern destructive confirmation dialog
        .confirmationDialog(
            "Delete property?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let p = deleteTarget {
                    withAnimation(.snappy) { s.deleteProperty(p.id) }
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        } message: {
            if let p = deleteTarget {
                Text("This will remove tenants linked to \(p.name).")
            }
        }

        // ✅ Modal is fine
        .sheet(isPresented: $showAdd) {
            AddEditPropertyView(store: s, property: editTarget)
        }
    }
}
