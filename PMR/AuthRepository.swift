//
//  AuthRepository.swift
//  PMR
//
//  Created by Sandil on 2025-10-15.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol AuthRepository {
    var currentUserId: String? { get }
    func signUp(fullName: String, email: String, password: String) async throws
    func login(email: String, password: String) async throws
    func logout() throws
}

final class FirebaseAuthRepository: AuthRepository {
    private let db = Firestore.firestore()
    var currentUserId: String? { Auth.auth().currentUser?.uid }

    func signUp(fullName: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid
        try await db.collection("users").document(uid).setData([
            "uid": uid,
            "fullName": fullName,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
        // optional:
        try? await result.user.sendEmailVerification()
    }

    func login(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func logout() throws { try Auth.auth().signOut() }
}
