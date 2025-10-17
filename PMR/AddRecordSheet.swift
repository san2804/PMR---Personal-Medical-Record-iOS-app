import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
            .sheet(isPresented: $showFilePicker) {
                FilePickerView()
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView()
            }
            .sheet(isPresented: $showNoteSheet) {
                CreateNoteView()
            }
            .onDisappear { onDone() }
        }
    }
}
