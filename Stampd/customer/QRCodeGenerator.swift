//
//  QRCodeGenerator.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    func generateQRCode(from string: String) -> UIImage {
        // convert string to data
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // high error correction
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        // Get the output image
        if let outputImage = filter.outputImage {
            // scale  QR code
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            // convert to UIImage
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        // return placeholder  if  fails
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// swiftUI wrapper to display QR codes
struct QRCodeView: View {
    let data: String
    let size: CGFloat
    
    var body: some View {
        let qrGenerator = QRCodeGenerator()
        let qrImage = qrGenerator.generateQRCode(from: data)
        
        Image(uiImage: qrImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    QRCodeView(data: "test123", size: 200)
}

