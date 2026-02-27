//
//  StatPill.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 25/02/26.
//


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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(valueText)
                .font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}