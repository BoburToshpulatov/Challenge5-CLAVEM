import SwiftUI

struct PropertiesCarousel: View {
    @Bindable var store: AppStore
    let onTapProperty: (Property) -> Void

    @State private var index = 0

    private let horizontalPadding: CGFloat = 16
    private let cardHeight: CGFloat = 242
    private let dotsSpace: CGFloat = 28

    private var properties: [Property] {
        store.properties
    }

    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let cardWidth = screenWidth - (horizontalPadding * 2)

            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(properties.enumerated()), id: \.element.id) { i, property in
                        Button {
                            onTapProperty(property)
                        } label: {
                            PropertyCard(
                                property: property,
                                tenantCount: store.tenantCount(for: property),
                                monthlyIncome: store.monthlyIncome(for: property)
                            )
                            .frame(width: cardWidth, height: cardHeight)
                        }
                        .buttonStyle(.plain)
                        .frame(width: screenWidth, height: cardHeight, alignment: .top)
                        .tag(i)
                        .accessibilityHint("Opens property details")
                    }
                }
                .frame(height: cardHeight)
                .tabViewStyle(.page(indexDisplayMode: properties.count > 1 ? .automatic : .never))

                Color.clear
                    .frame(height: properties.count > 1 ? dotsSpace : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: cardHeight + (properties.count > 1 ? dotsSpace : 0))
    }
}
