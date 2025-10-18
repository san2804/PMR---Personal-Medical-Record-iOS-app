// RecordsHomeView.swift
import SwiftUI

struct RecordsHomeView: View {
    @StateObject private var vm = RecordsViewModel()
    @State private var showAdd = false

    var body: some View {
        List {
            ForEach(vm.filtered) { r in
                NavigationLink {
                    RecordDetailView(record: r)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.title)
                                .font(.subheadline.weight(.semibold))
                            Text("\(r.provider) • \(r.category)")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        // Trailing date
                        Text(r.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { idx in
                Task { await vm.delete(at: idx) }
            }
        }
        .overlay {
            if vm.loading {
                ProgressView()
            } else if let e = vm.error {
                Text(e).foregroundColor(.red).padding()
            } else if vm.items.isEmpty {
                ContentUnavailableView(
                    "No records yet",
                    systemImage: "doc.text",
                    description: Text("Tap + to add a note.")
                )
            }
        }
        .searchable(text: $vm.query)
        .navigationTitle("Medical Records")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await vm.load() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddRecordSheet {
                Task { await vm.load() }
            }
        }
        .refreshable { await vm.load() }
        .task { await vm.load() }
    }
}

// MARK: - Detail

struct RecordDetailView: View {
    let record: TextRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Label(record.category, systemImage: "tag")
                    Label(record.provider, systemImage: "person.text.rectangle")

                    // Date displayed via a Text inside Label's title closure
                    Label {
                        Text(record.date, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
                .font(.caption)
                .foregroundStyle(.gray)

                Divider().padding(.vertical, 8)

                Text(record.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
    }
}
