//
//  FlickrPhoto.swift
//  FlickrPhotoSearch
//
//  Created by Bhargavi M on 10/8/26.
//

import Foundation

struct FlickrPhotoResponse: Decodable, Sendable {
    let items: [FlickrPhoto]
}

struct FlickrPhoto: Decodable, Identifiable, Hashable, Sendable {

    struct Media: Decodable, Hashable, Sendable {
        let m: URL
    }

    let title: String
    let link: URL
    let media: Media
    let author: String
    let tags: String
    let published: String

    // It uses the same ID when the same photo appears in different searches.
    var id: String {
        link.absoluteString
    }

    var imageURL: URL {
        media.m
    }

    var displayTitle: String {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Untitled photo" : title
    }
}
