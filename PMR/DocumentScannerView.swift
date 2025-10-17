//
//  DocumentScannerView.swift
//  PMR
//
//  Created by Sandil on 2025-10-16.
//


import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    var onSave: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(_ parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else { return }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("scan-\(UUID().uuidString).pdf")
            let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
            try? pdf.writePDF(to: tempURL, withActions: { ctx in
                for i in 0..<scan.pageCount {
                    ctx.beginPage()
                    scan.imageOfPage(at: i).draw(in: CGRect(x: 0, y: 0, width: 612, height: 792))
                }
            })
            parent.onSave(tempURL)
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
}
