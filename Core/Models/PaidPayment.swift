//
//  PaidPayment.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 05/03/26.
//


import Foundation

struct PaidPayment: Identifiable, Hashable {
    
    let id: UUID
    let tenantID: Tenant.ID
    let tenantName: String
    let tenantImageName: String?
    let propertyName: String
    
    let amount: Decimal
    let paidDate: Date
    let dueDate: Date
}