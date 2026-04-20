import SwiftUI

struct HomeView: View {

    @Bindable var store: AppStore

    private let pagePadding: CGFloat = 16

    @State private var selectedProperty: Property? = nil
    @State private var selectedTenant: Tenant? = nil
    @State private var showAddProperty = false

    var body: some View {
        let s = store
        let hasProperties = !s.properties.isEmpty
        let hasTenants = !s.tenants.filter(\.isActive).isEmpty

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                HomeOverviewStatsSection(store: store)

                remindersSection(store: s)

                propertiesSection(
                    store: s,
                    hasProperties: hasProperties
                )

                if hasTenants {
                    tenantsSection(store: s)
                }
            }
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Clavem")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedProperty) { property in
            PropertyDetailView(
                store: store,
                propertyID: property.id
            )
        }
        .navigationDestination(item: $selectedTenant) { tenant in
            TenantDetailView(
                store: store,
                tenantID: tenant.id
            )
        }
        .sheet(isPresented: $showAddProperty) {
            AddEditPropertyView(store: store)
        }
    }
}

private extension HomeView {

    func remindersSection(store s: AppStore) -> some View {
        VStack(spacing: 8) {

            NavigationLink {
                RemindersView(store: store)
            } label: {
                SectionHeader(title: "Reminders")
                    .padding(.horizontal, pagePadding)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens reminders")

            NavigationLink {
                RemindersView(store: store)
            } label: {
                RemindersSummaryCard(
                    countThisMonth: s.upcomingThisMonthCount,
                    nextDue: s.nextDueThisMonth
                )
                .padding(.horizontal, pagePadding)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows upcoming reminders and opens reminders")
        }
    }

    func propertiesSection(
        store s: AppStore,
        hasProperties: Bool
    ) -> some View {
        VStack(spacing: 8) {

            NavigationLink {
                PropertiesListView(store: store)
            } label: {
                SectionHeader(title: "Properties")
                    .padding(.horizontal, pagePadding)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens all properties")

            if hasProperties {
                PropertiesCarousel(store: store) { property in
                    selectedProperty = property
                }            } else {
                elegantEmptyPropertyCard
            }
        }
    }

    func tenantsSection(store s: AppStore) -> some View {
        VStack(spacing: 8) {

            NavigationLink {
                TenantsListView(store: store)
            } label: {
                SectionHeader(title: "Tenants")
                    .padding(.horizontal, pagePadding)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens all tenants")

            TenantsCarouselLarge(store: store) { tenant in
                selectedTenant = tenant
            }
        }
    }

    var elegantEmptyPropertyCard: some View {
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

                    Text("Start managing rent, tenants, bills, reminders, and occupancy in one place.")
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
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding(24)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal, pagePadding)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add your first property")
        .accessibilityHint("Opens the add property form")
    }
}
