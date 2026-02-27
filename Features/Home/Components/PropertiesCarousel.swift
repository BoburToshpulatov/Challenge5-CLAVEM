import SwiftUI

struct PropertiesCarousel: View {
    let properties: [Property]
    let onTapProperty: (Property) -> Void

    @State private var index = 0

    private let horizontalPadding: CGFloat = 16   // same as headline
    private let cardHeight: CGFloat = 240
    private let gap: CGFloat = 16                 // division between cards

    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width

            // Card width leaves equal 16 padding on both sides
            let cardWidth = screenWidth - (horizontalPadding * 2)

            TabView(selection: $index) {
                ForEach(Array(properties.enumerated()), id: \.offset) { i, property in

                    ZStack {
                        PropertyCard(property: property)
                            .frame(width: cardWidth, height: cardHeight)
                            .onTapGesture {
                                onTapProperty(property)
                            }
                    }
                    .frame(width: screenWidth)        // full page width
                    .padding(.horizontal, gap / 2)    // real division
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
        .frame(height: cardHeight)
    }
}
