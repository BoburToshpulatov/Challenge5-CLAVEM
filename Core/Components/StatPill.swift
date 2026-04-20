import SwiftUI

struct StatPill: View {
    let title: String
    let valueText: String

    init(title: String, value: String) {
        self.title = title
        self.valueText = value
    }

    init(title: String, value: Decimal, isCurrency: Bool) {
        self.title = title
        self.valueText = isCurrency ? value.formatted(.currency(code: "EUR")) : "\(value)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.68))
                .lineLimit(1)

            Text(valueText)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(valueText)")
    }
}
