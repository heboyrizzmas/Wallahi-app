//
//  NotificationManager.swift
//  TaskFlow
//
//  Wraps UNUserNotificationCenter to request permission and
//  schedule / cancel local notifications tied to a TaskItem.
//

import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification auth error: \(error.localizedDescription)")
            }
        }
    }

    /// Schedules a one-time notification for the given task's due date.
    func schedule(for task: TaskItem) {
        cancel(for: task)

        guard task.dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.hasLocation
            ? "Reminder at \(task.locationName ?? "your saved location")"
            : (task.notes.isEmpty ? "It's time!" : task.notes)
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: task.dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    func cancel(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
}
