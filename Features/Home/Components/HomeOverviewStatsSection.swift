import SwiftUI
import UserNotifications

struct HomeOverviewStatsSection: View {
    @Bindable var store: AppStore
    @StateObject private var notificationManager = NotificationManager.shared

    private let pagePadding: CGFloat = 16

    var body: some View {
        let s = store

        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.title3.bold())
                .padding(.horizontal, pagePadding)
                .accessibilityAddTraits(.isHeader)

            heroCard(store: s)

            compactStatsRow(store: s)

            if shouldShowReminderPrompt {
                reminderPromptCard
            }
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
        }
    }
}

private extension HomeOverviewStatsSection {

    var shouldShowReminderPrompt: Bool {
        notificationManager.authorizationStatus == .notDetermined ||
        notificationManager.authorizationStatus == .denied
    }

    func heroCard(store s: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Collected this month")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.72))

                    Text(s.collectedThisMonthIncome, format: .currency(code: "EUR"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                summaryBadge(
                    title: s.collectionRateText,
                    tint: s.collectedThisMonthIncome > 0 ? .green : .secondary
                )
            }

            Divider()

            HStack(spacing: 16) {
                summaryMetric(
                    title: "Expected",
                    value: s.expectedThisMonthIncome.formatted(.currency(code: "EUR")),
                    accent: .primary
                )

                summaryMetric(
                    title: "Overdue",
                    value: s.overdueAmountThisMonth.formatted(.currency(code: "EUR")),
                    accent: s.overdueAmountThisMonth > 0 ? .red : .secondary
                )
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .padding(.horizontal, pagePadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Collected this month \(s.collectedThisMonthIncome.formatted(.currency(code: "EUR"))), collection rate \(s.collectionRateText), expected \(s.expectedThisMonthIncome.formatted(.currency(code: "EUR"))), overdue \(s.overdueAmountThisMonth.formatted(.currency(code: "EUR")))"
        )
    }

    func compactStatsRow(store s: AppStore) -> some View {
        HStack(spacing: 12) {
            compactStatCard(
                title: "Properties",
                value: "\(s.activePropertiesCount)"
            )

            compactStatCard(
                title: "Active tenants",
                value: "\(s.activeTenantsCount)"
            )
        }
        .padding(.horizontal, pagePadding)
    }

    var reminderPromptCard: some View {
        Button {
            if notificationManager.authorizationStatus == .denied {
                    AppSettingsOpener.open()
                } else {
                    Task {
                        let granted = await notificationManager.requestPermissionIfNeeded()
                        if granted {
                            await notificationManager.refreshAuthorizationStatus()
                        }
                    }
                }
            }  label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.indigo.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "bell.badge")
                        .font(.headline)
                        .foregroundStyle(.indigo)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(reminderPromptTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(reminderPromptSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: notificationManager.authorizationStatus == .denied ? "arrow.up.right.square" : "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, pagePadding)
        .accessibilityLabel(reminderPromptTitle)
        .accessibilityHint(reminderPromptSubtitle)
    }

    var reminderPromptTitle: String {
        switch notificationManager.authorizationStatus {
        case .denied:
            return "Notifications are off"
        default:
            return "Turn on payment reminders"
        }
    }

    var reminderPromptSubtitle: String {
        switch notificationManager.authorizationStatus {
        case .denied:
            return "Enable notifications in Settings to receive rent reminders."
        default:
            return "Get notified when rent is due so you can stay on top of payments."
        }
    }

    func compactStatCard(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.68))

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }

    func summaryMetric(
        title: String,
        value: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.68))

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func summaryBadge(
        title: String,
        tint: Color
    ) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .clipShape(Capsule())
            .lineLimit(1)
    }
}
