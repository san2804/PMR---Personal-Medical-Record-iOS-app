import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PhotoPickerView: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        init(_ parent: PhotoPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                parent.dismiss()
                return
            }

            let provider = result.itemProvider

            // 1) Prefer an actual file URL if the provider can give one.
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                    defer { DispatchQueue.main.async { self.parent.dismiss() } }
                    if let url = url {
                        // This is a temporary, readable file URL (good for direct upload).
                        self.parent.onPicked(url)
                        return
                    }

                    // 2) Fallback: export UIImage -> JPEG temp file.
                    self.loadUIImageThenWriteTemp(provider: provider)
                }
                return
            }

            // 3) Last resort: try UIImage path directly.
            loadUIImageThenWriteTemp(provider: provider)
        }

        private func loadUIImageThenWriteTemp(provider: NSItemProvider) {
            provider.loadObject(ofClass: UIImage.self) { obj, err in
                defer { DispatchQueue.main.async { self.parent.dismiss() } }
                guard err == nil, let image = obj as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.9) else {
                    if let err = err { print("Photo load error:", err) }
                    return
                }

                let tmp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).jpg")
                do {
                    try data.write(to: tmp, options: .atomic)
                    self.parent.onPicked(tmp)
                } catch {
                    print("Temp JPEG write error:", error)
                }
            }
        }
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .images
        cfg.selectionLimit = 1
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}
