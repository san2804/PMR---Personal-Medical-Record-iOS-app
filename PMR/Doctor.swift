import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Doctor: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String

    var fullName: String
    var specialty: String

    var clinicName: String?
    var phone: String?
    var email: String?
    var address: String?

    var createdAt: Timestamp
    var updatedAt: Timestamp?
}
