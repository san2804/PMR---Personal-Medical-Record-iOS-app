import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class DoctorsViewModel: ObservableObject {
    @Published var items: [Doctor] = []
    @Published var loading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - Load all doctors
    func load() async {
        guard let uid else { return }
        loading = true; error = nil
        defer { loading = false }

        do {
            let snap = try await db.collection("doctors")
                .whereField("userId", isEqualTo: uid)
                .order(by: "fullName")
                .getDocuments()

            self.items = snap.documents.map { Doctor(id: $0.documentID, data: $0.data()) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Add new doctor
    func add(_ input: DoctorInput) async throws {
        guard let uid else { return }
        let now = Timestamp(date: Date())

        var data = [String: Any]()
        data["userId"] = uid
        data["fullName"] = input.fullName.trimmed()
        data["specialty"] = input.specialty.trimmed()
        if let v = input.clinicName.nilIfBlank() { data["clinicName"] = v }   // <-- no ?
        if let v = input.phone.nilIfBlank()      { data["phone"] = v }        // <-- no ?
        if let v = input.email.nilIfBlank()      { data["email"] = v }        // <-- no ?
        if let v = input.address.nilIfBlank()    { data["address"] = v }      // <-- no ?
        data["createdAt"] = now
        data["updatedAt"] = now

        let ref = try await db.collection("doctors").addDocument(data: data)

        var newDoctor = Doctor(id: ref.documentID, data: data)
        newDoctor.updatedAt = now
        insertAlphabetically(newDoctor)
    }

    // MARK: - Update existing doctor
    func update(_ id: String, with input: DoctorInput) async throws {
        guard let uid else { return }

        var patch = [String: Any]()
        patch["userId"] = uid
        patch["fullName"] = input.fullName.trimmed()
        patch["specialty"] = input.specialty.trimmed()
        if let v = input.clinicName.nilIfBlank() { patch["clinicName"] = v }  // <-- no ?
        if let v = input.phone.nilIfBlank()      { patch["phone"] = v }       // <-- no ?
        if let v = input.email.nilIfBlank()      { patch["email"] = v }       // <-- no ?
        if let v = input.address.nilIfBlank()    { patch["address"] = v }     // <-- no ?
        patch["updatedAt"] = FieldValue.serverTimestamp()

        try await db.collection("doctors").document(id).setData(patch, merge: true)
        await load()
    }

    // MARK: - Delete
    func delete(at offsets: IndexSet) async {
        let ids = offsets.compactMap { items[$0].id }
        for index in offsets.sorted(by: >) { items.remove(at: index) }
        for id in ids { try? await db.collection("doctors").document(id).delete() }
    }

    private func insertAlphabetically(_ doctor: Doctor) {
        let idx = items.firstIndex { $0.fullName.lowercased() > doctor.fullName.lowercased() } ?? items.count
        items.insert(doctor, at: idx)
    }
}

// Input DTO
struct DoctorInput {
    var fullName: String = ""
    var specialty: String = ""
    var clinicName: String? = nil
    var phone: String? = nil
    var email: String? = nil
    var address: String? = nil

    var isValid: Bool {
        !fullName.trimmed().isEmpty && !specialty.trimmed().isEmpty
    }
}

// Helpers
private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
private extension Optional where Wrapped == String {
    func nilIfBlank() -> String? {
        guard let s = self?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}
