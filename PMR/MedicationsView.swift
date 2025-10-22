// MedicationsView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MedicationsView: View {
    @StateObject private var vm = MedicationsVM()
    @State private var showEditor = false
    @State private var editTarget: Medication?

    var body: some View {
        List {
            let active = vm.filtered.filter { $0.isActiveNow }
            let past   = vm.filtered.filter { !$0.isActiveNow }

            Section("Active") {
                ForEach(active) { m in
                    MedicationRow(med: m)
                        .contentShape(Rectangle())
                        .onTapGesture { editTarget = m; showEditor = true }
                }
                .onDelete { idx in
                    let ids = idx.map { active[$0].id! }
                    Task { await vm.delete(ids: ids) }
                }
            }

            Section("Past") {
                ForEach(past) { m in
                    MedicationRow(med: m).foregroundStyle(.secondary)
                }
                .onDelete { idx in
                    let ids = idx.map { past[$0].id! }
                    Task { await vm.delete(ids: ids) }
                }
            }
        }
        .overlay {
            if vm.loading { ProgressView() }
            else if let e = vm.error { Text(e).foregroundStyle(.red).padding() }
            else if vm.items.isEmpty {
                ContentUnavailableView("No medications",
                                       systemImage: "pills.fill",
                                       description: Text("Tap + to add your first medication."))
            }
        }
        .searchable(text: $vm.query)
        .navigationTitle("Medications")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editTarget = nil; showEditor = true } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await vm.load() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showEditor) {
            MedicationEditor(existing: editTarget) { result in
                switch result {
                case .create(let m): Task { await vm.add(m) }
                case .update(let id, let patch): Task { await vm.update(id, patch: patch) }
                }
            }
        }
    }
}

private struct MedicationRow: View {
    let med: Medication
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 8).fill(.purple))

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name).font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    if let s = med.strength, !s.isEmpty { Text(s) }
                    if let f = med.frequency, !f.isEmpty { Text("• \(f)") }
                }
                .font(.caption).foregroundStyle(.secondary)
                if let pres = med.prescribedBy, !pres.isEmpty {
                    Text(pres).font(.caption2).foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text(med.startDate, style: .date).font(.caption)
                if let end = med.endDate {
                    Text("– \(end.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
