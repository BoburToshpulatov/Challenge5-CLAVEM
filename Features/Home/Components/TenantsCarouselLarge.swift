import SwiftUI

struct TenantsCarouselLarge: View {
    @Bindable var store: AppStore
    let onTap: (Tenant) -> Void

    private let pagePadding: CGFloat = 16

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(store.tenants) { tenant in
                    TenantCardLarge(
                        tenant: tenant,
                        propertyName: store.propertyName(for: tenant),
                        status: store.status(for: tenant)
                    )
                    .frame(width: 300) // keep your chosen width
                    .onTapGesture { onTap(tenant) }
                }
            }
            .padding(.horizontal, pagePadding)
//            .padding(.vertical, 6)
        }
    }
}
