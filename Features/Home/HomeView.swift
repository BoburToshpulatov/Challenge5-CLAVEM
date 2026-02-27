import SwiftUI

struct HomeView: View {
    @Bindable var store: AppStore
    private let pagePadding: CGFloat = 16

    @State private var selectedProperty: Property? = nil

    var body: some View {
        let s = store

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                Text("Dashboard")
                    .font(.largeTitle.bold())
                    .padding(.horizontal, pagePadding)
                    .padding(.top, 6)

                // MARK: - Reminders
                VStack(spacing: 8) {
                    NavigationLink {
                        RemindersView(store: s)
                    } label: {
                        SectionHeader(title: "Reminders")
                            .padding(.horizontal, pagePadding)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        RemindersView(store: s)
                    } label: {
                        RemindersSummaryCard(
                            countThisMonth: store.upcomingThisMonthCount,
                            nextDue: store.nextDueThisMonth
                        )
                        .padding(.horizontal, pagePadding)
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Properties
                VStack(spacing: 8) {
                    NavigationLink {
                        PropertiesListView(store: store)
                    } label: {
                        SectionHeader(title: "Properties")
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)

                    PropertiesCarousel(properties: s.properties) { property in
                        selectedProperty = property
                    }
                }


                // MARK: - Tenants
                VStack(spacing: 8) {
                    SectionHeader(title: "Tenants")
                    .padding(.horizontal, pagePadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 14) {
                            ForEach(s.tenants) { tenant in
                                TenantCardLarge(
                                    tenant: tenant,
                                    propertyName: s.propertyName(for: tenant),
                                    status: s.status(for: tenant)
                                )
                                .frame(width: 300)
                                .onTapGesture {
                                    print("Tapped tenant:", tenant.name)
                                }
                            }
                        }
                        .padding(.horizontal, pagePadding)
//                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(item: $selectedProperty) { property in
                    PropertyDetailView(store: s, propertyID: property.id)
                }
    }
}
