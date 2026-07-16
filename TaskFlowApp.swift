//
//  TaskFlowApp.swift
//  TaskFlow
//
//  iOS 16 compatible entry point — uses TaskStore (JSON-backed)
//  instead of SwiftData's ModelContainer, which needs iOS 17+.
//

import SwiftUI

@main
struct TaskFlowApp: App {
    @StateObject private var store = TaskStore()

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
