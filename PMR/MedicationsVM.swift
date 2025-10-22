//
//  MedicationsVM.swift
//  PMR
//
//  Created by Sandil on 2025-10-22.
//


// MedicationsVM.swift
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class MedicationsVM: ObservableObject {
    @Published var items: [Medication] = []
    @Published var loading = false
    @Published var error: String?
    @Published var query = ""

    private let db = Firestore.firestore()

    var filtered: [Medication] {
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(query)
            || ($0.prescribedBy ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        loading = true; error = nil
        defer { loading = false }

        do {
            // Requires composite index: medications(userId ASC, startDate ASC)
            let snap = try await db.collection("medications")
                .whereField("userId", isEqualTo: uid)
                .order(by: "startDate")
                .getDocuments()

            self.items = snap.documents.compactMap { Medication(id: $0.documentID, data: $0.data()) }
        } catch {
            let ns = error as NSError
            self.error = ns.localizedDescription
            // Graceful fallback while index builds (code 9)
            if ns.code == 9 {
                do {
                    let snap = try await db.collection("medications")
                        .whereField("userId", isEqualTo: uid)
                        .getDocuments()
                    var local = snap.documents.compactMap { Medication(id: $0.documentID, data: $0.data()) }
                    local.sort { $0.startDate < $1.startDate }
                    self.items = local
                    self.error = nil
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func add(_ m: Medication) async {
        do {
            var toSave = m
            toSave.createdAt = Date(); toSave.updatedAt = Date()
            let ref = try await db.collection("medications").addDocument(data: toSave.asDict)
            var saved = toSave; saved.id = ref.documentID
            let idx = items.insertionIndex(by: { $0.startDate < $1.startDate }, for: saved)
            items.insert(saved, at: idx)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func update(_ id: String, patch: [String: Any]) async {
        do {
            var p = patch
            p["updatedAt"] = Timestamp(date: Date())
            try await db.collection("medications").document(id).setData(p, merge: true)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(ids: [String]) async {
        items.removeAll { ids.contains($0.id ?? "") }
        for id in ids {
            do { try await db.collection("medications").document(id).delete() }
            catch { self.error = error.localizedDescription }
        }
    }
}
