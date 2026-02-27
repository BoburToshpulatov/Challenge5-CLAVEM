import SwiftUI

struct PropertyDetailView: View {
    @Bindable var store: AppStore
    let propertyID: Property.ID

    private let pagePadding: CGFloat = 16

    var body: some View {
        let s = store
        guard let property = s.properties.first(where: { $0.id == propertyID }) else {
            return AnyView(ContentUnavailableView("Property not found", systemImage: "house"))
        }

        let tenants = s.tenants(for: property)
        let income = s.monthlyIncome(for: property)

        return AnyView(
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    AvatarView(
                        name: property.name,
                        imageName: property.imageName,
                        imageData: property.imageData,
                        size: CGSize(width: UIScreen.main.bounds.width - (pagePadding * 2), height: 240),
                        cornerRadius: 26
                    )
                    .padding(.horizontal, pagePadding)
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(property.name)
                            .font(.largeTitle.bold())

                        Text("\(property.addressLine), \(property.city)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, pagePadding)

                    HStack(spacing: 12) {
                        StatPill(title: "Tenants", value: "\(tenants.count)")
                        StatPill(title: "Monthly", value: income, isCurrency: true)
                    }
                    .padding(.horizontal, pagePadding)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rooms")
                            .font(.title3.bold())

                        if property.rooms.isEmpty {
                            Text("Whole property rental")
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            ForEach(property.rooms) { room in
                                HStack {
                                    Text(room.name)
                                    Spacer()
                                    // later: show tenants in that room
                                }
                                .padding(12)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                    .padding(.horizontal, pagePadding)
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Tenants")
                                .font(.title3.bold())
                            Spacer()
                            Button {
                                // next step: Add tenant for this property
                            } label: {
                                Image(systemName: "plus")
                            }
                        }

                        if tenants.isEmpty {
                            Text("No tenants yet")
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            ForEach(tenants) { t in
                                HStack(spacing: 12) {
                                    AvatarView(
                                        name: t.name,
                                        imageName: t.imageName,
                                        size: CGSize(width: 44, height: 44),
                                        cornerRadius: 14
                                    )
                                    Text(t.name)
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(12)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                    .padding(.horizontal, pagePadding)
                    .padding(.top, 4)
                }
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Property")
            .navigationBarTitleDisplayMode(.inline)
        )
    }
}
