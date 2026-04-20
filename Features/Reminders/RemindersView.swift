import SwiftUI

struct RemindersView: View {

    @Bindable var store: AppStore

    private let pagePadding: CGFloat = 16

    enum Tab: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case paid = "Paid"

        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .upcoming
    @State private var shareText: String? = nil
    @State private var toast: (String, ToastBanner.Kind)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                tabPicker
                content
            }
            .padding(.horizontal, pagePadding)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: shareBinding) { payload in
            ShareSheet(items: [payload.text]) {
                Haptics.success()
                showToast("Reminder sent", kind: .success)
            }
        }
        .overlay(alignment: .top) {
            toastOverlay
        }
    }
}

private extension RemindersView {

    var tabPicker: some View {
        Picker("Reminders", selection: $selectedTab) {
            ForEach(Tab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Reminder category")
    }

    @ViewBuilder
    var content: some View {
        switch selectedTab {
        case .upcoming:
            upcomingList
        case .overdue:
            overdueList
        case .paid:
            paidList
        }
    }

    var upcomingList: some View {
        let items = store.upcomingThisMonth

        return Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No upcoming payments",
                    systemImage: "checkmark.circle"
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        UpcomingPaymentCard(
                            item: item,
                            messageText: store.reminderMessage(for: item),
                            onRemind: { text in
                                shareText = text
                            },
                            onDelay: { newDate in
                                store.setDelay(
                                    tenantID: item.tenantID,
                                    newDueDate: newDate
                                )
                                Haptics.warning()
                                showToast("Payment delayed", kind: .warning)
                            },
                            onConfirmPaid: {
                                Haptics.success()
                                withAnimation(.easeOut(duration: 0.2)) {
                                    store.markPaid(tenantID: item.tenantID)
                                }
                                showToast("Payment marked as paid", kind: .success)
                            }
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
    }

    var overdueList: some View {
        let items = store.overdueThisMonth

        return Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No overdue payments",
                    systemImage: "checkmark.circle"
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        UpcomingPaymentCard(
                            item: item,
                            messageText: store.reminderMessage(for: item),
                            onRemind: { text in
                                shareText = text
                            },
                            onDelay: { newDate in
                                store.setDelay(
                                    tenantID: item.tenantID,
                                    newDueDate: newDate
                                )
                                Haptics.warning()
                                showToast("Payment delayed", kind: .warning)
                            },
                            onConfirmPaid: {
                                Haptics.success()
                                withAnimation(.easeOut(duration: 0.2)) {
                                    store.markPaid(tenantID: item.tenantID)
                                }
                                showToast("Payment marked as paid", kind: .success)
                            }
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
    }

    var paidList: some View {
        let items = store.paidPaymentsThisMonth

        return Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No paid payments this month",
                    systemImage: "tray"
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { paid in
                        PaidPaymentCard(paid: paid)
                    }
                }
            }
        }
    }

    var shareBinding: Binding<SharePayload?> {
        Binding {
            shareText.map { SharePayload(text: $0) }
        } set: { payload in
            shareText = payload?.text
        }
    }

    var toastOverlay: some View {
        Group {
            if let toast {
                ToastBanner(text: toast.0, kind: toast.1)
                    .padding(.horizontal, pagePadding)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    func showToast(_ text: String, kind: ToastBanner.Kind) {
        withAnimation(.easeInOut(duration: 0.22)) {
            toast = (text, kind)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.22)) {
                toast = nil
            }
        }
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let text: String
}
