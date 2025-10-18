// TextRecord.swift
import Foundation
import FirebaseFirestore

struct TextRecord: Identifiable, Equatable {
    var id: String
    let userId: String
    let title: String
    let content: String
    let category: String
    let provider: String
    let dateOfService: Timestamp
    let createdAt: Timestamp?
    let updatedAt: Timestamp?

    init(
        id: String,
        userId: String,
        title: String,
        content: String,
        category: String,
        provider: String,
        dateOfService: Timestamp,
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.category = category
        self.provider = provider
        self.dateOfService = dateOfService
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(snap: DocumentSnapshot) {
        let data = snap.data() ?? [:]
        guard
            let userId = data["userId"] as? String,
            let title = data["title"] as? String,
            let content = data["content"] as? String,
            let category = data["category"] as? String,
            let provider = data["provider"] as? String,
            let date = data["dateOfService"] as? Timestamp
        else { return nil }

        self.init(
            id: snap.documentID,
            userId: userId,
            title: title,
            content: content,
            category: category,
            provider: provider,
            dateOfService: date,
            createdAt: data["createdAt"] as? Timestamp,
            updatedAt: data["updatedAt"] as? Timestamp
        )
    }

    var date: Date { dateOfService.dateValue() }
}
