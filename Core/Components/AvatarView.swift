import SwiftUI

struct AvatarView: View {
    let name: String
    let imageName: String?
    let imageData: Data?
    let size: CGSize
    let cornerRadius: CGFloat

    init(
        name: String,
        imageName: String? = nil,
        imageData: Data? = nil,
        size: CGSize,
        cornerRadius: CGFloat
    ) {
        self.name = name
        self.imageName = imageName
        self.imageData = imageData
        self.size = size
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        ZStack {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.blue.opacity(0.7))

                Text(initials(from: name))
                    .font(.system(size: min(size.width, size.height) * 0.34, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }
}
