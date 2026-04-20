import SwiftUI

struct PropertyCard: View {
    let property: Property
    let tenantCount: Int
    let monthlyIncome: Decimal

    private let radius: CGFloat = 22
    private let height: CGFloat = 242

    private var hasRealImage: Bool {
        property.imageData != nil || property.imageName != nil
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundLayer
            overlayGradient

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    statusBadge
                    Spacer(minLength: 0)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)

                        Text("\(property.addressLine), \(property.city)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }

                    metricsRow
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens property details")
    }
}

private extension PropertyCard {

    @ViewBuilder
    var backgroundLayer: some View {
        GeometryReader { geo in
            if hasRealImage {
                AvatarView(
                    name: property.name,
                    imageName: property.imageName,
                    imageData: property.imageData,
                    size: CGSize(width: geo.size.width, height: height),
                    cornerRadius: radius
                )
                .frame(width: geo.size.width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            } else {
                placeholderBackground
                    .frame(width: geo.size.width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            }
        }
    }

    var overlayGradient: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.14),
                .black.opacity(0.10),
                .black.opacity(0.26),
                .black.opacity(0.84)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    var placeholderBackground: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.58),
                Color.indigo.opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
        }
    }

    var statusBadge: some View {
        infoBadge(
            title: occupancyText,
            tint: occupancyTint
        )
    }

    var metricsRow: some View {
        HStack(spacing: 8) {
            metricPill(
                title: "Income",
                value: monthlyIncome.formatted(.currency(code: "EUR"))
            )

            if property.rentalMode == .byRooms {
                metricPill(
                    title: "Rooms",
                    value: "\(tenantCount)/\(property.rooms.count)"
                )
            } else {
                metricPill(
                    title: "Tenant",
                    value: tenantCount > 0 ? "1 active" : "Vacant"
                )
            }
        }
    }

    var occupancyText: String {
        switch property.rentalMode {
        case .wholeProperty:
            return tenantCount > 0 ? "Occupied" : "Vacant"
        case .byRooms:
            guard !property.rooms.isEmpty else { return "No rooms" }
            return "\(tenantCount)/\(property.rooms.count) occupied"
        }
    }

    var occupancyTint: Color {
        tenantCount > 0 ? .green : .orange
    }

    func infoBadge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.30))
            .clipShape(Capsule())
            .lineLimit(1)
    }

    func metricPill(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.white.opacity(0.78))

            Text(value)
                .foregroundStyle(.white)
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.black.opacity(0.22))
        .clipShape(Capsule())
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    var accessibilityLabel: String {
        let occupancy = occupancyText
        let income = monthlyIncome.formatted(.currency(code: "EUR"))
        return "\(property.name), \(property.addressLine), \(property.city), \(occupancy), monthly income \(income)"
    }
}
