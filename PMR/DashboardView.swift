import SwiftUI

// MARK: - Root Tabbed Dashboard
struct DashboardView: View {
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RecordsView()
                .tabItem {
                    Label("Records", systemImage: "doc.text.fill")
                }

            ShareView()
                .tabItem {
                    Label("Share", systemImage: "square.and.arrow.up.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.blue)
    }
}

// MARK: - Home Dashboard (first tab)
struct HomeDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header with logo and greeting
                    HStack(spacing: 15) {
                        Image("PMRLogo") // add to Assets as PMRLogo
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome Back,")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Sandil 👋")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Quick summary cards
                    HStack(spacing: 16) {
                        SummaryCard(icon: "heart.fill", title: "Health Score", value: "82")
                        SummaryCard(icon: "doc.text.fill", title: "Records", value: "12")
                    }
                    .padding(.horizontal)

                    // Quick Access section
                    Text("Quick Access")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        DashboardCard(
                            title: "Medical Records",
                            subtitle: "View, upload, and organize files",
                            icon: "folder.fill",
                            color: .blue
                        )
                        DashboardCard(
                            title: "Doctors",
                            subtitle: "Your healthcare contacts",
                            icon: "stethoscope",
                            color: .green
                        )
                        DashboardCard(
                            title: "Appointments",
                            subtitle: "Upcoming visits & reminders",
                            icon: "calendar.badge.clock",
                            color: .orange
                        )
                        DashboardCard(
                            title: "Medications",
                            subtitle: "Track prescriptions & doses",
                            icon: "pills.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .background(Color.white)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
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
                .foregroundColor(.white)
                .padding(12)
                .background(Circle().fill(Color.blue))
            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 4)
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
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(color))
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 3)
    }
}

// MARK: - Placeholder Tabs (make real screens later)
struct RecordsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text("Your medical records will appear here.")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.ignoresSafeArea())
    }
}

struct ShareView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text("Share your reports securely.")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.ignoresSafeArea())
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text("Manage app preferences and account.")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
