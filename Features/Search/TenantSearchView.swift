//
//  TenantSearchView.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 08/03/26.
//


import SwiftUI

struct TenantSearchView: View {

    @Bindable var store: AppStore
    @Binding var searchText: String

    private let pagePadding: CGFloat = 16

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredTenants: [Tenant] {
        let activeTenants = store.tenants.filter(\.isActive)

        if trimmedSearch.isEmpty {
            return activeTenants
        }

        return activeTenants.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch) ||
            store.propertyName(for: $0).localizedCaseInsensitiveContains(trimmedSearch) ||
            (store.roomName(for: $0)?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                if store.tenants.filter(\.isActive).isEmpty {
                    emptyAppState
                } else if filteredTenants.isEmpty {
                    emptySearchState
                } else {
                    results
                }
            }
            .padding(.horizontal, pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Search tenants")
        .searchSuggestions {
            ForEach(store.tenants.filter(\.isActive).prefix(5)) { tenant in
                Text(tenant.name)
                    .searchCompletion(tenant.name)
            }
        }
    }
}

private extension TenantSearchView {

    var results: some View {
        VStack(spacing: 12) {
            ForEach(filteredTenants) { tenant in
                NavigationLink {
                    TenantDetailView(
                        store: store,
                        tenantID: tenant.id
                    )
                } label: {
                    searchResultCard(for: tenant)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens tenant details")
            }
        }
    }

    func searchResultCard(for tenant: Tenant) -> some View {
        HStack(spacing: 12) {

            AvatarView(
                name: tenant.name,
                imageName: tenant.imageName,
                imageData: tenant.imageData,
                size: CGSize(width: 46, height: 46),
                cornerRadius: 14
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(tenant.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(store.propertyName(for: tenant))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let roomName = store.roomName(for: tenant) {
                    Text(roomName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(store.currentAmountDue(for: tenant), format: .currency(code: "EUR"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(store.status(for: tenant).rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(tenant.name), \(store.propertyName(for: tenant)), \(store.currentAmountDue(for: tenant).formatted(.currency(code: "EUR"))), \(store.status(for: tenant).rawValue)"
        )
    }

    var emptySearchState: some View {
        ContentUnavailableView(
            "No tenants found",
            systemImage: "magnifyingglass",
            description: Text("Try searching by tenant name, property name, or room.")
        )
        .padding(.top, 40)
    }

    var emptyAppState: some View {
        ContentUnavailableView(
            "No tenants yet",
            systemImage: "person.crop.circle.badge.plus",
            description: Text("Add a tenant first to search through your records.")
        )
        .padding(.top, 40)
    }
}