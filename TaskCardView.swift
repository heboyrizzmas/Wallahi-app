//
//  TaskCardView.swift
//  TaskFlow
//
//  iOS 16 compatible — uses TaskStore.delete/save instead of
//  SwiftData's modelContext.
//

import SwiftUI

struct TaskCardView: View {
    @EnvironmentObject private var store: TaskStore
    @ObservedObject var task: TaskItem
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(alignment: .top, spacing: 14) {
                checkbox

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 10) {
                        Label(task.dueDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if task.hasLocation {
                            Label(task.locationName ?? "Location", systemImage: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundColor(.indigo)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                priorityDot
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.delete(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDetail) {
            AddTaskView(editingTask: task).environmentObject(store)
        }
    }

    private var checkbox: some View {
        Button {
            withAnimation(.spring()) {
                task.isCompleted.toggle()
                if task.isCompleted {
                    NotificationManager.shared.cancel(for: task)
                } else {
                    NotificationManager.shared.schedule(for: task)
                }
                store.save()
            }
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(task.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private var priorityDot: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 10, height: 10)
            .padding(.top, 4)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
