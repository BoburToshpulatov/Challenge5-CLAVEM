//
//  MockData.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 22/02/26.
//


import Foundation

enum MockData {
    static func makeStore() -> AppStore {
        let store = AppStore()

        let p1 = Property(name: "Via Roma 12", addressLine: "Via Roma 12", city: "Milan", imageName: "apartment1")
        let p2 = Property(name: "Corso Como 8", addressLine: "Corso Como 8", city: "Milan", imageName: "apartment2")
        let p3 = Property(name: "Brera Studio", addressLine: "Via Brera 5", city: "Milan", imageName: "apartment3")
        let p4 = Property(name: "Porta Nuova", addressLine: "Viale Liberazione 9", city: "Milan", imageName: "apartment4")
        let p5 = Property(name: "Navigli Loft", addressLine: "Alzaia Naviglio 20", city: "Milan", imageName: "apartment5")

        store.properties = [p1, p2, p3, p4, p5]

        let cal = Calendar.current
        let d1 = cal.date(byAdding: .day, value: 2, to: .now)!
        let d2 = cal.date(byAdding: .day, value: 5, to: .now)!
        let d3 = cal.date(byAdding: .day, value: 1, to: .now)!
        let d4 = cal.date(byAdding: .day, value: 7, to: .now)!
        let d5 = cal.date(byAdding: .day, value: 3, to: .now)!

        store.tenants = [
            Tenant(propertyID: p1.id, name: "Marco Rossi", imageName: "tenant1", monthlyRent: 900, nextDueDate: d1),
            Tenant(propertyID: p2.id, name: "Sara Bianchi", imageName: "tenant2", monthlyRent: 1200, nextDueDate: d2),
            Tenant(propertyID: p5.id, name: "Luca Conti", imageName: "tenant3", monthlyRent: 1500, nextDueDate: d3),
            Tenant(propertyID: p3.id, name: "Giulia Ferretti", imageName: nil, monthlyRent: 1000, nextDueDate: d4),
            Tenant(propertyID: p4.id, name: "Paolo Ricci", imageName: nil, monthlyRent: 1050, nextDueDate: d5)
        ]

        // Example delay (to prove reminder adjustment works)
        store.setDelay(tenantID: store.tenants[0].id, newDueDate: cal.date(byAdding: .day, value: 10, to: .now)!, reason: "Requested delay")

        return store
    }
}