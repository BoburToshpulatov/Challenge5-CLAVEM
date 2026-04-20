import SwiftUI
import SwiftData

@main
struct Landa: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            PropertyEntity.self,
            RoomEntity.self,
            TenantEntity.self,
            BillEntity.self,
            BillShareEntity.self,
            PaymentRecordEntity.self,
            OccupancyRecordEntity.self
        ])
    }
}
