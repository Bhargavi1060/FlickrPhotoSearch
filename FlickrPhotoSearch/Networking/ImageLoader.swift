//
//  ImageLoader.swift
//  FlickrPhotoSearch
//
//  Created by Bhargavi M on 10/8/26.
//

import Foundation
import ImageIO

struct PhotoData: Sendable {
    let data: Data
    let width: Int
    let height: Int
}

actor ImageLoader {

    static let shared = ImageLoader()
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func loadPhoto(from url: URL) async throws -> PhotoData {
        let (data, response) = try await urlSession.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlickrError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw FlickrError.serverError(httpResponse.statusCode)
        }
        try Task.checkCancellation()

        // Get the actual image width and height
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let width = properties[kCGImagePropertyPixelWidth] as? Int,
        let height = properties[kCGImagePropertyPixelHeight] as? Int,
        width > 0,
        height > 0 else {
            throw FlickrError.invalidImage
        }
        return PhotoData(data: data, width: width, height: height)
    }
}
