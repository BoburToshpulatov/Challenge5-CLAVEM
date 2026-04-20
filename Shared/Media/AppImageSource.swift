import SwiftUI
import UIKit

enum AppImageSource: String, CaseIterable, Identifiable {
    case photoLibrary
    case camera

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photoLibrary: return "Photo Library"
        case .camera: return "Camera"
        }
    }

    var systemImage: String {
        switch self {
        case .photoLibrary: return "photo.on.rectangle"
        case .camera: return "camera"
        }
    }

    var pickerSourceType: UIImagePickerController.SourceType {
        switch self {
        case .photoLibrary: return .photoLibrary
        case .camera: return .camera
        }
    }

    var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(pickerSourceType)
    }
}

struct AppUIKitImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (Data?) -> Void

    @Environment(\.dismiss) private var dismiss

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: AppUIKitImagePicker

        init(parent: AppUIKitImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            let data = image?.jpegData(compressionQuality: 0.85)
            parent.onImagePicked(data)
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
}
