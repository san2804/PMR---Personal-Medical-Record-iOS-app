//
//  AppointmentsVM.swift
//  PMR
//
//  Created by Sandil on 2025-10-19.
//


//
//  AppointmentsVM.swift
//  PMR
//
import SwiftUI
import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class AppointmentsVM: ObservableObject {
    @Published var items: [Appointment] = []
    @Published var loading = false
    @Published var error: String?
    @Published var query = ""

    private let db = Firestore.firestore()

    var filtered: [Appointment] {
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query)
            || ($0.provider ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        loading = true; error = nil
        defer { loading = false }

        do {
            let snap = try await db.collection("appointments")
                .whereField("userId", isEqualTo: uid)
                .order(by: "startAt", descending: false)
                .getDocuments()

            items = snap.documents.compactMap { doc in
                Appointment(id: doc.documentID, data: doc.data())
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func add(_ a: Appointment) async {
        do {
            var toSave = a
            toSave.createdAt = Date(); toSave.updatedAt = Date()
            let ref = try await db.collection("appointments").addDocument(data: toSave.asDict)
            var saved = toSave; saved.id = ref.documentID
            items.insert(saved, at: items.insertionIndex { $0.startAt > saved.startAt })
            try await Notifications.schedule(for: saved)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func update(_ id: String, patch: [String: Any]) async {
        do {
            var p = patch
            p["updatedAt"] = Timestamp(date: Date())
            try await db.collection("appointments").document(id).setData(p, merge: true)
            await load()
            if let updated = items.first(where: { $0.id == id }) {
                try await Notifications.reschedule(for: updated)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        let ids = offsets.compactMap { items[$0].id }
        items.remove(atOffsets: offsets)
        for id in ids {
            do {
                try await db.collection("appointments").document(id).delete()
                Notifications.cancel(id: id)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Local reminder scheduling (optional)
enum Notifications {
    static func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    static func schedule(for a: Appointment) async throws {
        guard let id = a.id, let mins = a.remindMinutesBefore else { return }
        let when = a.startAt.addingTimeInterval(TimeInterval(-mins * 60))
        let interval = max(5, when.timeIntervalSinceNow) // never negative, minimum 5s

        let content = UNMutableNotificationContent()
        content.title = a.title
        content.body = a.location ?? a.provider ?? "Upcoming appointment"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let req = UNNotificationRequest(identifier: "appt-\(id)", content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(req)
    }

    static func reschedule(for a: Appointment) async throws {
        cancel(id: a.id)
        try await schedule(for: a)
    }

    static func cancel(id: String?) {
        guard let id else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["appt-\(id)"])
    }
}
