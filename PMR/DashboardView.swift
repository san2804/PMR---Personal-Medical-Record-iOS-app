import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - ViewModel
@MainActor
final class DashboardVM: ObservableObject {
    @Published var displayName: String = "User"
    @Published var recordsCount: Int = 0
    @Published var loading: Bool = false
    @Published var error: String?

    private let db = Firestore.firestore()

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        loading = true; error = nil
        defer { loading = false }

        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            if let fullName = userDoc.data()?["fullName"] as? String, !fullName.isEmpty {
                displayName = fullName
            } else {
                displayName = "User"
            }

            let snap = try await db.collection("records")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()
            recordsCount = snap.documents.count
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Root Tabbed Dashboard
struct DashboardView: View {
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            RecordsHomeView()
                .tabItem { Label("Records", systemImage: "doc.text.fill") }

            ShareView()
                .tabItem { Label("Share", systemImage: "square.and.arrow.up.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.blue)
    }
}

// MARK: - Home Dashboard (first tab)
struct HomeDashboardView: View {
    @StateObject private var vm = DashboardVM()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header with logo and greeting
                    HStack(spacing: 15) {
                        Image("PMRLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .font(.headline)
                                .foregroundStyle(.secondary)   // adaptive

                            Text("\(vm.displayName) 👋")
                                .font(.title3.bold())
                                .foregroundStyle(.primary)     // adaptive
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Error
                    if let error = vm.error {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }

                    // Quick summary cards
                    HStack(spacing: 16) {
                        SummaryCard(icon: "heart.fill", title: "Health Score", value: "—")
                        SummaryCard(icon: "doc.text.fill", title: "Records", value: "\(vm.recordsCount)")
                    }
                    .padding(.horizontal)

                    // Quick Access section
                    Text("Quick Access")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        NavigationLink { RecordsHomeView() } label: {
                            DashboardCard(
                                title: "Medical Records",
                                subtitle: "View Notes of Your Records",
                                icon: "folder.fill",
                                color: .blue
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink { DoctorsView() } label: {
                            DashboardCard(
                                title: "Doctors",
                                subtitle: "Your healthcare contacts",
                                icon: "stethoscope",
                                color: .green
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink { AppointmentsView() } label: {
                            DashboardCard(
                                title: "Appointments",
                                subtitle: "Upcoming visits & reminders",
                                icon: "calendar.badge.clock",
                                color: .orange
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink { MedicationsView() } label: {
                            DashboardCard(
                                title: "Medications",
                                subtitle: "Track prescriptions & doses",
                                icon: "pills.fill",
                                color: .purple
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                .refreshable { await vm.load() }
            }
            .background(Color(.systemBackground)) // adaptive page bg
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if vm.loading {
                    ToolbarItem(placement: .topBarTrailing) { ProgressView() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await vm.load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task { await vm.load() }
        }
    }
}

// MARK: - Reusable Cards

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .padding(12)
                .background(Circle().fill(Color.blue))

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)   // adaptive

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)     // adaptive
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground)) // adaptive card bg
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
    }
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(color))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)    // adaptive

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)  // adaptive
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)      // adaptive subtle arrow
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
    }
}

// MARK: - Placeholder Views

struct ShareView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.largeTitle)
                .foregroundStyle(.blue)
            Text("Share your reports securely.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SettingsView: View {
    @EnvironmentObject var session: SessionViewModel
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) { session.logout() } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AppointmentsView: View {
    var body: some View {
        List { Text("Upcoming appointments") }
            .navigationTitle("Appointments")
    }
}

struct MedicationsView: View {
    var body: some View {
        List { Text("Your medications") }
            .navigationTitle("Medications")
    }
}

// MARK: - Preview
#Preview {
    Group {
        DashboardView()
            .environmentObject(SessionViewModel())
            .preferredColorScheme(.light)

        DashboardView()
            .environmentObject(SessionViewModel())
            .preferredColorScheme(.dark)
    }
}
