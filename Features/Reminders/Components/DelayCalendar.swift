import SwiftUI

struct DelayCalendar: View {

    let tenantName: String
    let originalDate: Date
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()

    var body: some View {

        VStack(spacing: 16) {

            Text("Delay payment")
                .font(.headline)

            DatePicker(
                "",
                selection: $selectedDate,
                in: Date()...,   // disables past dates
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)

            Button("Confirm delay") {
                onConfirm(selectedDate)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
