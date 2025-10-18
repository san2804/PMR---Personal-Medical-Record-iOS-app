import Foundation
import FirebaseFirestore

struct Doctor: Identifiable, Hashable {
    var id: String?                // plain String, no @DocumentID
    let userId: String

    var fullName: String
    var specialty: String

    var clinicName: String?
    var phone: String?
    var email: String?
    var address: String?

    var createdAt: Timestamp
    var updatedAt: Timestamp?

    // Build from Firestore dictionary
    init(id: String? = nil, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""

        self.fullName = data["fullName"] as? String ?? ""
        self.specialty = data["specialty"] as? String ?? ""

        self.clinicName = data["clinicName"] as? String
        self.phone = data["phone"] as? String
        self.email = data["email"] as? String
        self.address = data["address"] as? String

        self.createdAt = data["createdAt"] as? Timestamp ?? Timestamp(date: .init())
        self.updatedAt = data["updatedAt"] as? Timestamp
    }

    // Convert to Firestore dictionary
    func asDict() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "fullName": fullName,
            "specialty": specialty,
            "createdAt": createdAt
        ]
        if let clinicName { dict["clinicName"] = clinicName }
        if let phone { dict["phone"] = phone }
        if let email { dict["email"] = email }
        if let address { dict["address"] = address }
        if let updatedAt { dict["updatedAt"] = updatedAt }
        return dict
    }
}
