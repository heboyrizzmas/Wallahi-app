//
//  TaskItem.swift
//  TaskFlow
//
//  iOS 16 compatible version — plain Codable class.
//  (SwiftData/@Model requires iOS 17+, so storage is now handled
//  manually by TaskStore, saved as JSON in the Documents folder.)
//

import Foundation

final class TaskItem: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var notes: String
    @Published var dueDate: Date
    @Published var isCompleted: Bool
    let createdAt: Date

    @Published var hasLocation: Bool
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var locationName: String?

    @Published var priority: Priority

    init(
        title: String,
        notes: String = "",
        dueDate: Date,
        isCompleted: Bool = false,
        hasLocation: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        priority: Priority = .medium
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = .now
        self.hasLocation = hasLocation
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.priority = priority
    }

    enum Priority: String, Codable, CaseIterable {
        case low, medium, high

        var label: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }

    // MARK: - Codable (ObservableObject classes need manual conformance)

    private enum CodingKeys: String, CodingKey {
        case id, title, notes, dueDate, isCompleted, createdAt
        case hasLocation, latitude, longitude, locationName, priority
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        notes = try c.decode(String.self, forKey: .notes)
        dueDate = try c.decode(Date.self, forKey: .dueDate)
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        hasLocation = try c.decode(Bool.self, forKey: .hasLocation)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        locationName = try c.decodeIfPresent(String.self, forKey: .locationName)
        priority = try c.decode(Priority.self, forKey: .priority)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(notes, forKey: .notes)
        try c.encode(dueDate, forKey: .dueDate)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(hasLocation, forKey: .hasLocation)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encodeIfPresent(locationName, forKey: .locationName)
        try c.encode(priority, forKey: .priority)
    }
}
