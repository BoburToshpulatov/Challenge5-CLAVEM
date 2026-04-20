//
//  PaymentInstructions.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 04/03/26.
//


import Foundation

struct PaymentInstructions: Hashable {
    var payToName: String
    var iban: String?
    var cardLast4: String?
    var note: String?

    init(
        payToName: String = "Landlord",
        iban: String? = nil,
        cardLast4: String? = nil,
        note: String? = nil
    ) {
        self.payToName = payToName
        self.iban = iban
        self.cardLast4 = cardLast4
        self.note = note
    }
}