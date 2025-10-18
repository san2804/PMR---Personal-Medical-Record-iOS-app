import SwiftUI
import QuickLook
import SafariServices

struct FilePreviewView: View {
    let filePath: String
    let title: String

    var body: some View {
        Group {
            if isRemote, let url = URL(string: filePath) {
                _SafariPreview(url: url).edgesIgnoringSafeArea(.all)
            } else if FileManager.default.fileExists(atPath: filePath) {
                _LocalQuickLookPreview(filePath: filePath).edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.orange)
                    Text("File not found").font(.headline)
                    Text(filePath).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
    }

    private var isRemote: Bool {
        filePath.lowercased().hasPrefix("http://") || filePath.lowercased().hasPrefix("https://")
    }
}

// MARK: - Local QuickLook (file-scoped + unique name)
fileprivate struct _LocalQuickLookPreview: UIViewControllerRepresentable {
    let filePath: String

    func makeUIViewController(context: Context) -> QLPreviewController {
        let c = QLPreviewController()
        c.dataSource = context.coordinator
        return c
    }
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(filePath: filePath) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let filePath: String
        init(filePath: String) { self.filePath = filePath }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            URL(fileURLWithPath: filePath) as QLPreviewItem
        }
    }
}

// MARK: - Safari for remote URLs (file-scoped + unique name)
fileprivate struct _SafariPreview: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
