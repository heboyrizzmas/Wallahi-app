//
//  TaskStore.swift
//  TaskFlow
//
//  Replaces SwiftData's ModelContainer/@Query (iOS 17+ only) with a
//  simple JSON file saved to the app's Documents folder — works back
//  to iOS 13, well within iOS 16.7's requirements for the iPhone 8.
//

import Foundation
import Combine

final class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("tasks.json")
    }()

    init() {
        load()
    }

    func add(_ task: TaskItem) {
        tasks.append(task)
        save()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        NotificationManager.shared.cancel(for: task)
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save tasks: \(error.localizedDescription)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            tasks = try JSONDecoder().decode([TaskItem].self, from: data)
        } catch {
            print("Failed to load tasks: \(error.localizedDescription)")
        }
    }
}
