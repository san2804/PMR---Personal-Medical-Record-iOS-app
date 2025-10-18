import Foundation
import FirebaseFirestore

struct MedicalRecord: Identifiable {
    var id: String?
    let userId: String
    let title: String
    let provider: String
    let category: String
    let dateOfService: Timestamp
    let fileUrl: String          // <-- remote https URL
    let createdAt: Timestamp

    init(id: String? = nil, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""
        self.title = data["title"] as? String ?? ""
        self.provider = data["provider"] as? String ?? ""
        self.category = data["category"] as? String ?? "Other"
        self.dateOfService = data["dateOfService"] as? Timestamp ?? Timestamp(date: Date())
        self.fileUrl = data["fileUrl"] as? String ?? ""
        self.createdAt = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
    }

    func asDict() -> [String: Any] {
        [
            "userId": userId,
            "title": title,
            "provider": provider,
            "category": category,
            "dateOfService": dateOfService,
            "fileUrl": fileUrl,
            "createdAt": createdAt
        ]
    }
}
