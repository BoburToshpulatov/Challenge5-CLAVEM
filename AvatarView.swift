//
//  AvatarView.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 22/02/26.
//


import SwiftUI

struct AvatarView: View {
    let name: String
    let imageName: String?
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let imageName,
               !imageName.isEmpty,
               UIImage(named: imageName) != nil {

                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor)

                    Text(initials(from: name))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var backgroundColor: Color {
        let colors: [Color] = [
            .blue, .purple, .orange, .green, .indigo
        ]
        return colors[abs(name.hashValue) % colors.count]
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}
