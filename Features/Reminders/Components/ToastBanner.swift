//
//  ToastBanner.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 05/03/26.
//


import SwiftUI

struct ToastBanner: View {
    enum Kind { case success, info, warning }

    let text: String
    let kind: Kind

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(dotColor)

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(radius: 10, y: 6)
    }

    private var dotColor: Color {
        switch kind {
        case .success: return .green
        case .info: return .indigo
        case .warning: return .orange
        }
    }
}