import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import QuickLook

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

// MARK: - Records Home
struct RecordsHomeView: View {
    @State private var items: [RecordMeta] = []
    @State private var loading = false
    @State private var error: String?
    @State private var showAdd = false
    @State private var query = ""

    var body: some View {
        List {
            ForEach(filtered) { record in
                NavigationLink {
                    RecordDetailView(record: record)
                } label: {
                    RecordRow(r: record)
                }
            }
        }
        .overlay {
            if loading { ProgressView() }
            else if let e = error {
                Text(e)
                    .foregroundColor(.red)
                    .padding()
            } else if items.isEmpty {
                ContentUnavailableView(
                    "No records yet",
                    systemImage: "doc.text",
                    description: Text("Tap + to add a PDF, image, or scan.")
                )
            }
        }
        .searchable(text: $query)
        .navigationTitle("Medical Records")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await load() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showAdd) {
            AddRecordSheet { Task { await load() } }
        }
    }

    // MARK: - Filtered Search
    private var filtered: [RecordMeta] {
        query.isEmpty
        ? items
        : items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.provider.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Load from Firestore
    @MainActor
    private func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        loading = true; error = nil
        defer { loading = false }

        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("records")
                .whereField("userId", isEqualTo: uid)
                .order(by: "dateOfService", descending: true)
                .getDocuments()
            items = try snapshot.documents.compactMap { doc in
                try doc.data(as: RecordMeta.self)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Record Row
struct RecordRow: View {
    let r: RecordMeta

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(r.title)
                    .font(.subheadline.weight(.semibold))
                Text(r.provider)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
            Text(r.dateOfService.dateValue(), style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Record Detail View with Preview
struct RecordDetailView: View {
    let record: RecordMeta
    @State private var showPreview = false

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Title", value: record.title)
                LabeledContent("Provider", value: record.provider)
                LabeledContent("Category", value: record.category)
                LabeledContent(
                    "Date",
                    value: record.dateOfService.dateValue()
                        .formatted(date: .abbreviated, time: .omitted)
                )
            }

            Section("File") {
                if !record.filePath.isEmpty {
                    Text(record.filePath)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)

                    Button {
                        showPreview = true
                    } label: {
                        Label("Open File", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("No file linked to this record.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Record Details")
        .sheet(isPresented: $showPreview) {
            QuickLookPreview(filePath: record.filePath)
        }
    }
}

// MARK: - QuickLook Previewer
struct QuickLookPreview: UIViewControllerRepresentable {
    let filePath: String

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(filePath: filePath)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let filePath: String
        init(filePath: String) { self.filePath = filePath }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            URL(fileURLWithPath: filePath) as QLPreviewItem
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RecordsHomeView()
    }
}
