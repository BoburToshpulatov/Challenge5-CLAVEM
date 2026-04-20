import SwiftUI

struct AvatarView: View {
    let name: String
    let imageName: String?
    var imageData: Data? = nil
    let size: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

private extension AvatarView {

    var uiImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: placeholderColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: placeholderSymbol)
                    .font(symbolFont)
                    .foregroundStyle(.white.opacity(0.94))

                if shouldShowInitial {
                    Text(initials)
                        .font(initialFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            .padding(8)
        }
    }

    var placeholderSymbol: String {
        let lower = name.lowercased()

        if lower.contains("property") ||
            lower.contains("house") ||
            lower.contains("apartment") ||
            lower.contains("room") ||
            lower.contains("loft") {
            return "building.2.crop.circle.fill"
        }

        return "person.crop.circle.fill"
    }

    var placeholderColors: [Color] {
        if placeholderSymbol == "building.2.crop.circle.fill" {
            return [
                Color.indigo.opacity(0.70),
                Color.blue.opacity(0.85)
            ]
        } else {
            return [
                Color.orange.opacity(0.72),
                Color.pink.opacity(0.82)
            ]
        }
    }

    var initials: String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)).uppercased() }

        return parts.joined()
    }

    var shouldShowInitial: Bool {
        min(size.width, size.height) >= 54
    }

    var symbolFont: Font {
        let minSide = min(size.width, size.height)

        if minSide >= 120 {
            return .system(size: 34, weight: .medium)
        } else if minSide >= 72 {
            return .system(size: 24, weight: .medium)
        } else if minSide >= 44 {
            return .system(size: 18, weight: .medium)
        } else {
            return .system(size: 14, weight: .medium)
        }
    }

    var initialFont: Font {
        let minSide = min(size.width, size.height)

        if minSide >= 120 {
            return .title2
        } else if minSide >= 72 {
            return .headline
        } else {
            return .subheadline
        }
    }
}
