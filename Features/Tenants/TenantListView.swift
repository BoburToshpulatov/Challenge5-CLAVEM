import SwiftUI

struct TenantsListView: View {

    @Bindable var store: AppStore

    @State private var showAddTenant = false
    @State private var tenantToEdit: Tenant? = nil
    @State private var pendingArchiveTenant: Tenant? = nil

    private let pagePadding: CGFloat = 16

    private var activeTenants: [Tenant] {
        store.tenants
            .filter(\.isActive)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if activeTenants.isEmpty {
                    emptyState
                } else {
                    tenantCards
                }
            }
            .padding(.horizontal, pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tenants")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTenant = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add tenant")
                .accessibilityHint("Opens the form to add a tenant")
            }
        }
        .sheet(isPresented: $showAddTenant) {
            AddTenantView(store: store)
        }
        .sheet(item: $tenantToEdit) { tenant in
            AddTenantView(store: store, tenant: tenant)
        }
        .confirmationDialog(
            "Archive tenant?",
            isPresented: Binding(
                get: { pendingArchiveTenant != nil },
                set: { if !$0 { pendingArchiveTenant = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Archive", role: .destructive) {
                guard let tenant = pendingArchiveTenant else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.archiveTenant(tenant.id)
                }
                pendingArchiveTenant = nil
            }

            Button("Cancel", role: .cancel) {
                pendingArchiveTenant = nil
            }
        } message: {
            if let tenant = pendingArchiveTenant {
                Text("This will move \(tenant.name) out of active tenants and preserve their occupancy history.")
            }
        }
    }
}

private extension TenantsListView {

    var tenantCards: some View {
        VStack(spacing: 12) {
            ForEach(activeTenants) { tenant in
                NavigationLink {
                    TenantDetailView(
                        store: store,
                        tenantID: tenant.id
                    )
                } label: {
                    TenantRowCard(
                        tenant: tenant,
                        propertyName: store.propertyName(for: tenant),
                        status: store.status(for: tenant)
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        tenantToEdit = tenant
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button(role: .destructive) {
                        pendingArchiveTenant = tenant
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
                .contextMenu {
                    Button {
                        tenantToEdit = tenant
                    } label: {
                        Label("Edit Tenant", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        pendingArchiveTenant = tenant
                    } label: {
                        Label("Archive Tenant", systemImage: "archivebox")
                    }
                }
                .transition(.opacity)
                .accessibilityHint("Double tap to open tenant details. Swipe left for edit and archive actions.")
            }
        }
    }

    var emptyState: some View {
        Button {
            showAddTenant = true
        } label: {
            VStack(spacing: 18) {
                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 88, height: 88)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.blue)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Add your first tenant")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Create a tenant to track rent, reminders, rooms, and occupancy history.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                HStack(spacing: 10) {
                    Text("Add Tenant")
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
        .accessibilityLabel("Add your first tenant")
        .accessibilityHint("Opens the form to add a tenant")
    }
}
