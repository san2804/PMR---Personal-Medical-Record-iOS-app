//
//  RecordsViewModel.swift
//  PMR
//
//  Created by Sandil on 2025-10-18.
//


// RecordsViewModel.swift
import Foundation
import Combine

@MainActor
final class RecordsViewModel: ObservableObject {
    @Published var items: [TextRecord] = []
    @Published var query: String = ""
    @Published var loading = false
    @Published var error: String?

    private let repo = RecordRepository()

    var filtered: [TextRecord] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return items }
        return items.filter { r in
            r.title.localizedCaseInsensitiveContains(query) ||
            r.provider.localizedCaseInsensitiveContains(query) ||
            r.category.localizedCaseInsensitiveContains(query) ||
            r.content.localizedCaseInsensitiveContains(query)
        }
    }

    func load() async {
        loading = true; error = nil
        defer { loading = false }
        do { items = try await repo.fetchRecords() }
        catch { self.error = error.localizedDescription }
    }

    func addNote(title: String, content: String) async {
        do {
            try await repo.createTextRecord(title: title, content: content)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        let ids = offsets.map { filtered[$0].id }
        for id in ids {
            do { try await repo.deleteRecord(id) } catch { self.error = error.localizedDescription }
        }
        await load()
    }
}
