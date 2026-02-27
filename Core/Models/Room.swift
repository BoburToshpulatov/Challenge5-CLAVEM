//
//  Room.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 26/02/26.
//


import Foundation

struct Room: Identifiable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}