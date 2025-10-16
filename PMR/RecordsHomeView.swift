import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
      if items.isEmpty && !loading { ContentUnavailableView("No records yet", systemImage: "doc.text", description: Text("Tap + to add a PDF, image, or scan.")) }
      if let e = error { Text(e).foregroundColor(.red).padding() }
    }
    .searchable(text: $query)
    .navigationTitle("Medical Records")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { Button { showAdd = true } label: { Image(systemName: "plus") } }
      ToolbarItem(placement: .topBarTrailing) { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") } }
    }
    .task { await load() }
    .sheet(isPresented: $showAdd) { AddRecordSheet(onDone: { Task { await load() } }) }
  }

  private var filtered: [RecordMeta] {
    query.isEmpty ? items : items.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.provider.localizedCaseInsensitiveContains(query) }
  }

  @MainActor
  private func load() async {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    loading = true; error = nil
    defer { loading = false }
    do {
      let db = Firestore.firestore()
      let snap = try await db.collection("records").whereField("userId", isEqualTo: uid).order(by: "dateOfService", descending: true).getDocuments()
      self.items = try snap.documents.map { try $0.data(as: RecordMeta.self) }
    } catch { self.error = error.localizedDescription }
  }
}
