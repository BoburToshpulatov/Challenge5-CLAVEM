//
//  ActionPillStyle.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 04/03/26.
//


import SwiftUI

struct ActionPillStyle: ButtonStyle {

    enum Kind {
        case remind
        case delay
        case paid
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(background(configuration.isPressed))
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(border, lineWidth: 1)
            )
    }

    private func background(_ pressed: Bool) -> Color {
        switch kind {
        case .remind:
            return pressed ? .indigo.opacity(0.22) : .indigo.opacity(0.12)

        case .delay:
            return pressed ? .orange.opacity(0.22) : .orange.opacity(0.12)

        case .paid:
            return pressed ? .green.opacity(0.22) : .green.opacity(0.14)
        }
    }

    private var border: Color {
        switch kind {
        case .remind: return .indigo.opacity(0.35)
        case .delay: return .orange.opacity(0.35)
        case .paid: return .green.opacity(0.35)
        }
    }

    private var foreground: Color {
        switch kind {
        case .remind: return .indigo
        case .delay: return .orange
        case .paid: return .green
        }
    }
}