//
//  RecordRepository.swift
//  PMR
//
//  Created by Sandil on 2025-10-17.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UniformTypeIdentifiers

enum RecordRepoError: Error { case notLoggedIn, emptyFile }

struct RecordRepository {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func uploadAndCreateRecord(
        from localURL: URL,
        inferredUTType: UTType?,
        title: String?,
        provider: String = "Self",
        category: String = "Other",
        dateOfService: Date = Date()
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw RecordRepoError.notLoggedIn }

        // 1) Make a storage ref
        let ext = inferredUTType?.preferredFilenameExtension ?? localURL.pathExtension
        let safeExt = ext.isEmpty ? "dat" : ext
        let fileName = "\(UUID().uuidString).\(safeExt)"
        let path = "records/\(uid)/\(fileName)"
        let ref = storage.reference(withPath: path)

        // 2) Upload (by file URL)
        let meta = StorageMetadata()
        meta.contentType = inferredUTType?.preferredMIMEType ?? mimeType(for: safeExt)

        // If the file might be security-scoped, open access here (FilePicker case)
        let needsAccess = localURL.startAccessingSecurityScopedResource()
        defer { if needsAccess { localURL.stopAccessingSecurityScopedResource() } }

        let _ = try await ref.putFileAsync(from: localURL, metadata: meta)


        // 3) Get download URL
        let url = try await ref.downloadURL()

        // 4) Create Firestore doc (use download URL)
        let doc: [String: Any] = [
            "userId": uid,
            "title": (title?.isEmpty == false ? title! : localURL.lastPathComponent),
            "provider": provider,
            "category": category,
            "dateOfService": Timestamp(date: dateOfService),
            "fileUrl": url.absoluteString,
            "createdAt": FieldValue.serverTimestamp()
        ]
        _ = try await db.collection("records").addDocument(data: doc)
    }

    func fetchAll() async throws -> [MedicalRecord] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        let snap = try await db.collection("records")
            .whereField("userId", isEqualTo: uid)
            .order(by: "dateOfService", descending: true)
            .getDocuments()
        return snap.documents.map { MedicalRecord(id: $0.documentID, data: $0.data()) }
    }

    // basic MIME guesser
    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf": return "application/pdf"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}
