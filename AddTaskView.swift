//
//  AddTaskView.swift
//  TaskFlow
//
//  iOS 16 compatible — saves through TaskStore instead of
//  SwiftData's modelContext.
//

import SwiftUI
import CoreLocation

struct AddTaskView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    var editingTask: TaskItem?

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(3600)
    @State private var priority: TaskItem.Priority = .medium

    @State private var hasLocation: Bool = false
    @State private var locationName: String?
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var showingLocationPicker = false

    private var isEditing: Bool { editingTask != nil }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("What do you need to do?", text: $title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                    TextField("Notes (optional)", text: $notes)
                }

                Section(header: Text("When")) {
                    DatePicker("Date & time", selection: $dueDate)
                }

                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskItem.Priority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Location")) {
                    Toggle("Attach a location", isOn: $hasLocation.animation())

                    if hasLocation {
                        Button {
                            showingLocationPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text(locationName ?? "Choose on map")
                                    .foregroundColor(locationName == nil ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    initialCoordinate: coordinate,
                    onConfirm: { coord, name in
                        coordinate = coord
                        locationName = name
                    }
                )
            }
            .onAppear(perform: populateIfEditing)
        }
        .navigationViewStyle(.stack)
    }

    private func populateIfEditing() {
        guard let task = editingTask else { return }
        title = task.title
        notes = task.notes
        dueDate = task.dueDate
        priority = task.priority
        hasLocation = task.hasLocation
        locationName = task.locationName
        if let lat = task.latitude, let lon = task.longitude {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    private func save() {
        if let task = editingTask {
            task.title = title
            task.notes = notes
            task.dueDate = dueDate
            task.priority = priority
            task.hasLocation = hasLocation
            task.locationName = hasLocation ? locationName : nil
            task.latitude = hasLocation ? coordinate?.latitude : nil
            task.longitude = hasLocation ? coordinate?.longitude : nil
            store.save()
            NotificationManager.shared.schedule(for: task)
        } else {
            let task = TaskItem(
                title: title,
                notes: notes,
                dueDate: dueDate,
                hasLocation: hasLocation,
                latitude: hasLocation ? coordinate?.latitude : nil,
                longitude: hasLocation ? coordinate?.longitude : nil,
                locationName: hasLocation ? locationName : nil,
                priority: priority
            )
            store.add(task)
            NotificationManager.shared.schedule(for: task)
        }
        dismiss()
    }
}
