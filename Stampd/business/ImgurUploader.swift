//
//  ImgurUploader.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import Foundation

class ImgurUploader {
    private let clientID = "546c25a59c58ad7"
    
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImgurError.invalidImage
        }
        
        let base64Image = imageData.base64EncodedString()
        
        guard let url = URL(string: "https://api.imgur.com/3/image") else {
            throw ImgurError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Client-ID \(clientID)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "image": base64Image,
            "type": "base64"
        ])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImgurError.uploadFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let link = responseData["link"] as? String else {
            throw ImgurError.invalidResponse
        }
        
        return link
    }
    
    enum ImgurError: Error, LocalizedError {
        case invalidImage
        case invalidURL
        case uploadFailed
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not process image"
            case .invalidURL:
                return "Invalid URL"
            case .uploadFailed:
                return "Upload failed. Please try again."
            case .invalidResponse:
                return "Invalid response from server"
            }
        }
    }
}

