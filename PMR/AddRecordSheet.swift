//
//  AddRecordSheet.swift
//  PMR
//
//  Created by Sandil on 2025-10-16.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UniformTypeIdentifiers

struct AddRecordSheet: View {
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showScanner = false
    @State private var showFilePicker = false
    @State private var showPhotoPicker = false
    @State private var showNoteSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("Add") {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan document", systemImage: "doc.viewfinder")
                    }

                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Import from Files", systemImage: "folder")
                    }

                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Import from Photos", systemImage: "photo.on.rectangle")
                    }

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

            // MARK: - Document Scanner
            .sheet(isPresented: $showScanner) {
                DocumentScannerView(onSave: { url in
                    Task {
                        do {
                            try await RecordRepository().uploadAndCreateRecord(
                                from: url,
                                inferredUTType: .pdf,
                                title: url.deletingPathExtension().lastPathComponent
                            )
                            onDone()
                        } catch {
                            print("Upload error (Scanner):", error)
                        }
                    }
                })
            }

            // MARK: - File Picker
            .sheet(isPresented: $showFilePicker) {
                FilePickerView(onPicked: { url in
                    Task {
                        do {
                            try await RecordRepository().uploadAndCreateRecord(
                                from: url,
                                inferredUTType: UTType(filenameExtension: url.pathExtension),
                                title: url.deletingPathExtension().lastPathComponent
                            )
                            onDone()
                        } catch {
                            print("Upload error (Files):", error)
                        }
                    }
                })
            }

            // MARK: - Photo Picker
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView(onPicked: { url in
                    Task {
                        do {
                            try await RecordRepository().uploadAndCreateRecord(
                                from: url,
                                inferredUTType: .jpeg,
                                title: url.deletingPathExtension().lastPathComponent
                            )
                            onDone()
                        } catch {
                            print("Upload error (Photos):", error)
                        }
                    }
                })
            }

            // MARK: - Note Creator
            .sheet(isPresented: $showNoteSheet) {
                CreateNoteView(onSave: { title, content in
                    Task {
                        do {
                            // Write to temp file before upload
                            let tmp = FileManager.default.temporaryDirectory
                                .appendingPathComponent("\(UUID().uuidString).txt")
                            try content.data(using: .utf8)?.write(to: tmp, options: .atomic)

                            try await RecordRepository().uploadAndCreateRecord(
                                from: tmp,
                                inferredUTType: .plainText,
                                title: title,
                                category: "Note"
                            )
                            onDone()
                        } catch {
                            print("Upload error (Note):", error)
                        }
                    }
                })
            }
        }
    }
}
