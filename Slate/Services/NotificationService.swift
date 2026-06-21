import Foundation
import UserNotifications

/// 로컬 알림(매일 기록 리마인더) 관리 서비스
/// - 외부 서버 없이 동작하는 self-contained 기능
/// - 소셜/푸시 알림은 추후 Firebase Cloud Messaging 단계에서 추가 (CloudSyncService 참고)
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let dailyReminderID = "slate.daily.reminder"

    /// 알림 권한 요청
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
    }

    /// 현재 알림 권한 상태 조회
    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    /// 매일 지정 시각에 반복되는 기록 리마인더 예약 (기본 오후 8시)
    func scheduleDailyReminder(hour: Int = 20, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        let content = UNMutableNotificationContent()
        content.title = "Today's Slate"
        content.body = "Capture one moment of who you're becoming. 📸"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    /// 예약된 리마인더 취소
    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }
}
