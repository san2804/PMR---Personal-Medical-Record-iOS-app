//
//  Appointment.swift
//  PMR
//

import Foundation
import FirebaseFirestore

struct Appointment: Identifiable, Equatable {
    var id: String?                 // Firestore doc id
    let userId: String
    var title: String
    var provider: String?
    var location: String?
    var notes: String?
    var startAt: Date
    var endAt: Date?
    var isAllDay: Bool
    var remindMinutesBefore: Int?
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Firestore <-> Dictionary (manual, no FirebaseFirestoreSwift)
extension Appointment {
    init?(id: String?, data: [String: Any]) {
        guard
            let userId = data["userId"] as? String,
            let title = data["title"] as? String,
            let startTS = data["startAt"] as? Timestamp,
            let isAllDay = data["isAllDay"] as? Bool,
            let createdTS = data["createdAt"] as? Timestamp,
            let updatedTS = data["updatedAt"] as? Timestamp
        else { return nil }

        self.id = id
        self.userId = userId
        self.title = title
        self.provider = data["provider"] as? String
        self.location = data["location"] as? String
        self.notes = data["notes"] as? String
        self.startAt = startTS.dateValue()
        self.endAt = (data["endAt"] as? Timestamp)?.dateValue()
        self.isAllDay = isAllDay
        self.remindMinutesBefore = data["remindMinutesBefore"] as? Int
        self.createdAt = createdTS.dateValue()
        self.updatedAt = updatedTS.dateValue()
    }

    var asDict: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "title": title,
            "startAt": Timestamp(date: startAt),
            "isAllDay": isAllDay,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        dict["provider"] = provider as Any
        dict["location"] = location as Any
        dict["notes"] = notes as Any
        dict["endAt"] = endAt.map { Timestamp(date: $0) } as Any
        dict["remindMinutesBefore"] = remindMinutesBefore as Any
        return dict
    }
}

// MARK: - Small helpers
extension Array {
    /// Keep array sorted by a comparison key.
    func insertionIndex(where belongsBefore: (Element) -> Bool) -> Int {
        var low = 0, high = count
        while low < high {
            let mid = (low + high) / 2
            if belongsBefore(self[mid]) { high = mid } else { low = mid + 1 }
        }
        return low
    }
}
