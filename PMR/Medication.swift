//
//  Medication.swift
//  PMR
//
//  Created by Sandil on 2025-10-22.
//


// Medication.swift
import Foundation
import FirebaseFirestore

struct Medication: Identifiable, Equatable {
    var id: String?
    var userId: String

    // Core
    var name: String
    var strength: String?         // e.g. "500 mg"
    var form: String?             // e.g. "tablet", "syrup"
    var route: String?            // e.g. "oral"
    var frequency: String?        // e.g. "1-0-1"
    var instructions: String?     // free text dosage directions

    // Dates
    var startDate: Date
    var endDate: Date?            // nil = still taking

    // Meta
    var prescribedBy: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // Convenience
    var isActiveNow: Bool { endDate == nil || endDate! >= Date() }

    // Firestore ↔︎ Swift
    init(id: String? = nil,
         userId: String,
         name: String,
         strength: String? = nil,
         form: String? = nil,
         route: String? = nil,
         frequency: String? = nil,
         instructions: String? = nil,
         startDate: Date,
         endDate: Date? = nil,
         prescribedBy: String? = nil,
         notes: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.strength = strength
        self.form = form
        self.route = route
        self.frequency = frequency
        self.instructions = instructions
        self.startDate = startDate
        self.endDate = endDate
        self.prescribedBy = prescribedBy
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(id: String, data: [String: Any]) {
        func ts(_ k: String) -> Date? {
            (data[k] as? Timestamp)?.dateValue()
        }
        guard let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let start = ts("startDate"),
              let created = ts("createdAt"),
              let updated = ts("updatedAt")
        else { return nil }

        self.id = id
        self.userId = userId
        self.name = name
        self.strength = data["strength"] as? String
        self.form = data["form"] as? String
        self.route = data["route"] as? String
        self.frequency = data["frequency"] as? String
        self.instructions = data["instructions"] as? String
        self.startDate = start
        self.endDate = ts("endDate")
        self.prescribedBy = data["prescribedBy"] as? String
        self.notes = data["notes"] as? String
        self.createdAt = created
        self.updatedAt = updated
    }

    var asDict: [String: Any] {
        [
            "userId": userId,
            "name": name,
            "strength": strength as Any,
            "form": form as Any,
            "route": route as Any,
            "frequency": frequency as Any,
            "instructions": instructions as Any,
            "startDate": Timestamp(date: startDate),
            "endDate": endDate.map { Timestamp(date: $0) } as Any,
            "prescribedBy": prescribedBy as Any,
            "notes": notes as Any,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}

// tiny helper like the one you’re using elsewhere
extension Array {
    func insertionIndex(by areInIncreasingOrder: (Element, Element) -> Bool, for element: Element) -> Int {
        var low = 0, high = count
        while low < high {
            let mid = (low + high) / 2
            if areInIncreasingOrder(self[mid], element) { low = mid + 1 } else { high = mid }
        }
        return low
    }
}
