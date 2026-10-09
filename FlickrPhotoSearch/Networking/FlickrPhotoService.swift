//
//  FlickrPhotoService.swift
//  FlickrPhotoSearch
//
//  Created by Bhargavi M on 10/8/26.
//

import Foundation

protocol FlickrPhotoService: Sendable {
    func searchPhotos(tags: String) async throws -> [FlickrPhoto]
}

enum FlickrError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to create the search URL."
        case .invalidResponse:
            return "Invalid response from the server."
        case .serverError(let statusCode):
            return "Request failed with status code \(statusCode). Please try again."
        case .invalidImage:
            return "Unable to load the image."
        }
    }
}

actor FlickrService: FlickrPhotoService {

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    static func makeSearchURL(tags: String) throws -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.flickr.com"
        urlComponents.path = "/services/feeds/photos_public.gne"

        // Handles spaces and special characters in the search text.
        urlComponents.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "nojsoncallback", value: "1"),
            URLQueryItem(name: "tags", value: tags),
            URLQueryItem(name: "tagmode", value: "all")
        ]

        guard let url = urlComponents.url else {
            throw FlickrError.invalidURL
        }
        return url
    }

    func searchPhotos(tags: String) async throws -> [FlickrPhoto] {
         let url = try Self.makeSearchURL(tags: tags)
         let (data, response) = try await urlSession.data(from: url)
         
         guard let httpResponse = response as? HTTPURLResponse else {
         throw FlickrError.invalidResponse
         }
         
         // Make sure the request was successful.
         guard (200..<300).contains(httpResponse.statusCode) else {
         throw FlickrError.serverError(httpResponse.statusCode)
         }
         
         try Task.checkCancellation()
         
         let result = try JSONDecoder().decode(FlickrPhotoResponse.self, from: data)
         
         // Make sure each photo has a unique ID.
         var photoIDs = Set<String>()
         
         return result.items.filter { photo in
         photoIDs.insert(photo.id).inserted
         }
    }
}
