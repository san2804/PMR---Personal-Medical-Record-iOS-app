import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class DoctorsViewModel: ObservableObject {
    @Published var items: [Doctor] = []
    @Published var loading = false
    @Published var error: String?

    private let db = Firestore.firestore()

    var uid: String? { Auth.auth().currentUser?.uid }

    func load() async {
        guard let uid = uid else { return }
        loading = true; error = nil
        defer { loading = false }
        do {
            let snap = try await db.collection("doctors")
                .whereField("userId", isEqualTo: uid)
                .order(by: "fullName")
                .getDocuments()

            items = try snap.documents.compactMap { try $0.data(as: Doctor.self) }
        } catch { self.error = error.localizedDescription }
    }

    func add(_ input: DoctorInput) async throws {
        guard let uid = uid else { return }
        let now = Timestamp(date: Date())
        var doc = Doctor(
            userId: uid,
            fullName: input.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            specialty: input.specialty.trimmingCharacters(in: .whitespacesAndNewlines),
            clinicName: input.clinicName?.nilIfBlank(),
            phone: input.phone?.nilIfBlank(),
            email: input.email?.nilIfBlank(),
            address: input.address?.nilIfBlank(),
            createdAt: now,
            updatedAt: now
        )
        let ref = try db.collection("doctors").addDocument(from: doc)
        doc.id = ref.documentID
        items.insert(doc, at: items.insertionIndex(for: doc.fullName))
    }

    func update(_ id: String, with input: DoctorInput) async throws {
        guard let uid = uid else { return }
        let patch: [String: Any] = [
            "userId": uid,
            "fullName": input.fullName,
            "specialty": input.specialty,
            "clinicName": input.clinicName?.nilIfBlank() as Any,
            "phone": input.phone?.nilIfBlank() as Any,
            "email": input.email?.nilIfBlank() as Any,
            "address": input.address?.nilIfBlank() as Any,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("doctors").document(id).setData(patch, merge: true)
        // refresh local
        await load()
    }

    func delete(at offsets: IndexSet) async {
        let ids = offsets.compactMap { items[$0].id }
        items.remove(atOffsets: offsets)
        for id in ids {
            try? await db.collection("doctors").document(id).delete()
        }
    }
}

extension Array where Element == Doctor {
    /// Keep list alphabetized by name when inserting a single item
    func insertionIndex(for name: String) -> Int {
        let lower = name.lowercased()
        return firstIndex { $0.fullName.lowercased() > lower } ?? count
    }
}

struct DoctorInput {
    var fullName: String = ""
    var specialty: String = ""
    var clinicName: String? = nil
    var phone: String? = nil
    var email: String? = nil
    var address: String? = nil

    var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !specialty.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

private extension Optional where Wrapped == String {
    func nilIfBlank() -> String? {
        guard let s = self?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}
