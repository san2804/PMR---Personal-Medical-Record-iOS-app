import SwiftUI
import VisionKit
import UniformTypeIdentifiers

struct DocumentScannerView: UIViewControllerRepresentable {
    var onSave: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(_ parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                parent.dismiss()
                return
            }

            // Render to a temporary PDF; caller uploads this to Firebase Storage.
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString).pdf")

            // Letter size @ 72dpi. Adjust if you need A4.
            let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

            do {
                try renderer.writePDF(to: tmpURL) { ctx in
                    for i in 0..<scan.pageCount {
                        ctx.beginPage()
                        scan.imageOfPage(at: i).draw(in: pageRect)
                    }
                }

                // Return the temp PDF URL directly (no local persistence).
                parent.onSave(tmpURL)
            } catch {
                print("Scanner save error: \(error)")
            }

            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
}
