//
//  ContentView.swift
//  TaskFlow
//
//  iOS 16 compatible — reads from TaskStore (EnvironmentObject)
//  instead of SwiftData's @Query.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var showingAddTask = false

    private var todayTasks: [TaskItem] {
        store.tasks.filter { Calendar.current.isDateInToday($0.dueDate) && !$0.isCompleted }
    }
    private var upcomingTasks: [TaskItem] {
        store.tasks.filter { !Calendar.current.isDateInToday($0.dueDate) && $0.dueDate > .now && !$0.isCompleted }
    }
    private var overdueTasks: [TaskItem] {
        store.tasks.filter { $0.dueDate < .now && !Calendar.current.isDateInToday($0.dueDate) && !$0.isCompleted }
    }
    private var completedTasks: [TaskItem] {
        store.tasks.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                backgroundGradient

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        if store.tasks.isEmpty {
                            emptyState
                        } else {
                            section(title: "Overdue", tasks: overdueTasks, tint: .red)
                            section(title: "Today", tasks: todayTasks, tint: .indigo)
                            section(title: "Upcoming", tasks: upcomingTasks, tint: .blue)
                            section(title: "Completed", tasks: completedTasks, tint: .green)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                addButton
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView().environmentObject(store)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Your Tasks")
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    @ViewBuilder
    private func section(title: String, tasks: [TaskItem], tint: Color) -> some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(tint)

                ForEach(tasks) { task in
                    TaskCardView(task: task)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(Color(.tertiaryLabel))
            Text("No tasks yet")
                .font(.title3.bold())
            Text("Tap the + button to create your first reminder.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private var addButton: some View {
        Button {
            showingAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: .indigo.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color.indigo.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
