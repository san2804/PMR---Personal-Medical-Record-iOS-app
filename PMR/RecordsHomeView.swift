import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestore  // for @DocumentID
// (Optional later) import PhotosUI, FirebaseStorage for uploads

// MARK: - Model
struct RecordMeta: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let title: String
    let provider: String
    let category: String
    let dateOfService: Timestamp
    let filePath: String
    let createdAt: Timestamp
}

// MARK: - Home (list)
struct RecordsHomeView: View {
    @State private var items: [RecordMeta] = []
    @State private var loading = false
    @State private var error: String?
    @State private var showAdd = false
    @State private var query = ""

    var body: some View {
        List {
            ForEach(filtered) { r in
                NavigationLink { RecordDetailView(record: r) } label: {
                    RecordRow(r: r)
                }
            }
        }
        .overlay {
            if loading { ProgressView() }
            if let e = error { Text(e).foregroundColor(.red).padding() }
            if items.isEmpty && !loading && error == nil {
                ContentUnavailableView("No records yet",
                                       systemImage: "doc.text",
                                       description: Text("Tap + to add a PDF, image, or scan."))
            }
        }
        .searchable(text: $query)
        .navigationTitle("Medical Records")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showAdd) {
            AddRecordSheet { Task { await load() } }
        }
    }

    private var filtered: [RecordMeta] {
        query.isEmpty
        ? items
        : items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.provider.localizedCaseInsensitiveContains(query)
        }
    }

    @MainActor
    private func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        loading = true; error = nil
        defer { loading = false }
        do {
            let db = Firestore.firestore()
            let snap = try await db.collection("records")
                .whereField("userId", isEqualTo: uid)
                .order(by: "dateOfService", descending: true)
                .getDocuments()
            items = try snap.documents.map { try $0.data(as: RecordMeta.self) }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Row
struct RecordRow: View {
    let r: RecordMeta
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
            VStack(alignment: .leading, spacing: 2) {
                Text(r.title).font(.subheadline.weight(.semibold))
                Text(r.provider).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Text(r.dateOfService.dateValue(), style: .date)
                .font(.caption).foregroundColor(.gray)
        }
    }
}

// MARK: - Detail (stub)
struct RecordDetailView: View {
    let record: RecordMeta
    var body: some View {
        List {
            LabeledContent("Title", value: record.title)
            LabeledContent("Provider", value: record.provider)
            LabeledContent("Category", value: record.category)
            LabeledContent("Date", value: record.dateOfService.dateValue()
                .formatted(date: .abbreviated, time: .omitted))
            LabeledContent("Storage Path", value: record.filePath)
        }
        .navigationTitle("Record")
    }
}

// MARK: - Add Sheet (stub—compiles now; wire uploads later)
struct AddRecordSheet: View {
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Add") {
                    Button { /* hook up scanner */ } label: {
                        Label("Scan document", systemImage: "doc.viewfinder")
                    }
                    Button { /* hook up Files picker */ } label: {
                        Label("Import from Files", systemImage: "folder")
                    }
                    Button { /* hook up Photos picker */ } label: {
                        Label("Import from Photos", systemImage: "photo.on.rectangle")
                    }
                    Button { /* open note editor */ } label: {
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
        }
    }
}
