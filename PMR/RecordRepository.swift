// RecordRepository.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

struct RecordRepository {
    private let db = Firestore.firestore()

    private func requireUID() throws -> String {
        if let uid = Auth.auth().currentUser?.uid { return uid }
        throw NSError(domain: "PMR", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
    }

    // CREATE
    func createTextRecord(
        title: String,
        content: String,
        category: String = "Note",
        provider: String = "Self",
        dateOfService: Date = Date()
    ) async throws {
        let uid = try requireUID()
        let data: [String: Any] = [
            "userId": uid,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "content": content,
            "category": category,
            "provider": provider,
            "dateOfService": Timestamp(date: dateOfService),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        _ = try await db.collection("records").addDocument(data: data)
    }

    // READ (list)
    func fetchRecords() async throws -> [TextRecord] {
        let uid = try requireUID()
        let snap = try await db.collection("records")
            .whereField("userId", isEqualTo: uid)
            .order(by: "dateOfService", descending: true)
            .getDocuments()
        return snap.documents.compactMap(TextRecord.init(snap:))
    }

    // UPDATE
    func updateRecord(_ id: String, title: String, content: String, category: String, provider: String, dateOfService: Date) async throws {
        let uid = try requireUID() // ensures login & rules alignment
        let patch: [String: Any] = [
            "userId": uid, // keep same owner
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "content": content,
            "category": category,
            "provider": provider,
            "dateOfService": Timestamp(date: dateOfService),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("records").document(id).setData(patch, merge: true)
    }

    // DELETE
    func deleteRecord(_ id: String) async throws {
        try await db.collection("records").document(id).delete()
    }
}
