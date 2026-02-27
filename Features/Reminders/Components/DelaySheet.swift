//
//  DelaySheet.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 23/02/26.
//


import SwiftUI

struct DelaySheet: View {
    let tenantName: String
    let originalDueDate: Date
    let onSave: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newDate: Date

    init(tenantName: String, originalDueDate: Date, onSave: @escaping (Date) -> Void) {
        self.tenantName = tenantName
        self.originalDueDate = originalDueDate
        self.onSave = onSave
        _newDate = State(initialValue: originalDueDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tenant") {
                    Text(tenantName)
                }

                Section("Temporary due date") {
                    DatePicker("New date", selection: $newDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Delay payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(newDate)
                        dismiss()
                    }
                }
            }
        }
    }
}