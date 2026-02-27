import SwiftUI

struct RemindersView: View {
    @Bindable var store: AppStore
    private let pagePadding: CGFloat = 16

    @State private var delayTarget: UpcomingPayment? = nil
    @State private var viewMode: ViewMode = .all

    enum ViewMode: String, CaseIterable, Identifiable {
        case all = "All"
        case byProperty = "By Property"
        var id: String { rawValue }
    }

    var body: some View {
        let s = store

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // Mode toggle
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if s.upcomingPaymentsThisMonth.isEmpty {
                    ContentUnavailableView(
                        "No upcoming payments this month",
                        systemImage: "checkmark.circle"
                    )
                    .padding(.top, 40)
                } else {
                    switch viewMode {
                    case .all:
                        ForEach(s.upcomingPaymentsThisMonth) { item in
                            UpcomingPaymentCard(
                                item: item,
                                onDelay: { delayTarget = item },
                                onConfirmPaid: {
                                    withAnimation(.snappy) {
                                        s.markPaid(tenantID: item.tenantID)
                                    }
                                }
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }

                    case .byProperty:
                        ForEach(s.remindersGroupedThisMonth, id: \.propertyName) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(section.propertyName)
                                        .font(.headline)

                                    Spacer()

                                    Text("\(section.items.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 6)

                                ForEach(section.items) { item in
                                    UpcomingPaymentCard(
                                        item: item,
                                        onDelay: { delayTarget = item },
                                        onConfirmPaid: {
                                            withAnimation(.snappy) {
                                                s.markPaid(tenantID: item.tenantID)
                                            }
                                        }
                                    )
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, pagePadding)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reminders")
        .sheet(item: $delayTarget) { item in
            DelaySheet(
                tenantName: item.tenantName,
                originalDueDate: item.dueDate
            ) { newDate in
                s.setDelay(tenantID: item.tenantID, newDueDate: newDate)
            }
        }
    }
}
