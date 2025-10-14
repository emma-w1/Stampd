//
//  ImagePicker.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var logoUrl: String
    @Binding var isUploading: Bool
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
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
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.selectedImage = image
                            // Upload to Imgur
                            self.uploadToImgur(image: image)
                        }
                    }
                }
            }
        }
        
        func uploadToImgur(image: UIImage) {
            parent.isUploading = true
            
            Task {
                do {
                    let url = try await ImgurUploader().uploadImage(image)
                    await MainActor.run {
                        self.parent.logoUrl = url
                        self.parent.isUploading = false
                    }
                } catch {
                    print("❌ Upload failed: \(error.localizedDescription)")
                    await MainActor.run {
                        self.parent.isUploading = false
                    }
                }
            }
        }
    }
}

