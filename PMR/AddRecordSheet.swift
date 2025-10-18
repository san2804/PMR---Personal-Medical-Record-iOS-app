//
//  AddRecordSheet.swift
//  PMR
//
//  Created by Sandil on 2025-10-16.
//

import SwiftUI

struct AddRecordSheet: View {
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showNoteSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("Add") {
                    Button {
                        showNoteSheet = true
                    } label: {
                        Label("Create note", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Add Record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showNoteSheet) {
                CreateNoteView { title, content in
                    Task {
                        do {
                            try await RecordRepository().createTextRecord(
                                title: title,
                                content: content,
                                category: "Note",
                                provider: "Self",
                                dateOfService: Date()
                            )
                        } catch {
                            print("Create note failed:", error.localizedDescription)
                        }
                        onDone()
                    }
                }
            }
            .onDisappear { onDone() }
        }
    }
}
