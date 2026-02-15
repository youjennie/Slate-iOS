import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    // 이제 한 장이 아니라 여러 장을 담을 수 있게 [UIImage] 배열로 받습니다.
    @Binding var selectedImages: [UIImage]
    var detectedDate: Date
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 3 // 0으로 설정하면 무제한 선택 가능!
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            let group = DispatchGroup()
            var images: [UIImage] = []
            
            for result in results {
                group.enter()
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let uiImage = image as? UIImage {
                            images.append(uiImage)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.selectedImages = images
            }
        }
    }
}
