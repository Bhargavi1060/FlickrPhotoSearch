//
//  FlickrPhotoSearchTests.swift
//  FlickrPhotoSearchTests
//
//  Created by Bhargavi M on 10/8/26.
//

import Foundation
import XCTest
@testable import FlickrPhotoSearch

final class PhotoSearchViewModelTests: XCTestCase {

    @MainActor
    func testSearchReturnsPhotos() async throws {
        let photo = try makePhoto()
        let service = MockPhotoService(photos: [photo])
        let viewModel = PhotoSearchViewModel(service: service)

        await viewModel.search("bird")

        XCTAssertEqual(viewModel.photos.map(\.id), [photo.id])
        XCTAssertEqual(viewModel.state, .loaded)
    }

    @MainActor
    func testSearchFailureShowsError() async {
        let service = MockPhotoService(shouldFail: true)
        let viewModel = PhotoSearchViewModel(service: service)

        await viewModel.search("bird")

        guard case .failed(let message) = viewModel.state else {
            return XCTFail("Expected a failed state")
        }

        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(viewModel.photos.isEmpty)
    }

    @MainActor
    func testEmptySearchClearsResults() async throws {
        let photo = try makePhoto()
        let service = MockPhotoService(photos: [photo])
        let viewModel = PhotoSearchViewModel(service: service)

        await viewModel.search("bird")
        XCTAssertFalse(viewModel.photos.isEmpty)

        await viewModel.search(" , ")

        XCTAssertTrue(viewModel.photos.isEmpty)
        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testClearingSearchTextClearsResultsImmediately() async throws {
        let photo = try makePhoto()
        let service = MockPhotoService(photos: [photo])
        let viewModel = PhotoSearchViewModel(service: service)

        viewModel.searchText = "bird"
        await viewModel.search("bird")
        XCTAssertFalse(viewModel.photos.isEmpty)

        viewModel.searchText = ""

        XCTAssertTrue(viewModel.photos.isEmpty)
        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testTypingSearchesOnlyLatestText() async {
        let requestReceived = expectation(
            description: "Search request received"
        )

        let service = RecordingPhotoService {
            requestReceived.fulfill()
        }
        let viewModel = PhotoSearchViewModel(service: service)

        // Only the final text should reach the service.
        viewModel.searchText = "b"
        viewModel.searchText = "bi"
        viewModel.searchText = "bird"

        await fulfillment(of: [requestReceived], timeout: 2)

        let searches = await service.searches
        XCTAssertEqual(searches, ["bird"])
    }

    @MainActor
    func testTypingDoesNotSearchImmediately() async {
        let requestReceived = expectation(description: "Search should wait for the debounce")
        requestReceived.isInverted = true

        let service = RecordingPhotoService {
            requestReceived.fulfill()
        }
        let viewModel = PhotoSearchViewModel(service: service)

        viewModel.searchText = "bird"

        await fulfillment(of: [requestReceived], timeout: 0.1)

        let searches = await service.searches
        XCTAssertTrue(searches.isEmpty)

        // Clear the text before the pending search starts.
        viewModel.searchText = ""
    }

    private func makePhoto() throws -> FlickrPhoto {
        let json = #"""
        {
            "title": "Bird",
            "link": "https://www.flickr.com/photos/testuser/1",
            "media": {
                "m": "https://example.com/bird.jpg"
            },
            "author": "Test Author",
            "tags": "forest bird",
            "published": "2026-10-08T12:00:00Z"
        }
        """#
        return try JSONDecoder().decode(FlickrPhoto.self, from: Data(json.utf8))
    }
}

private struct MockPhotoService: FlickrPhotoService {

    let photos: [FlickrPhoto]
    let shouldFail: Bool

    init(
        photos: [FlickrPhoto] = [],
        shouldFail: Bool = false
    ) {
        self.photos = photos
        self.shouldFail = shouldFail
    }

    func searchPhotos(tags: String) async throws -> [FlickrPhoto] {
        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }

        return photos
    }
}

private actor RecordingPhotoService: FlickrPhotoService {

    private(set) var searches: [String] = []
    private let onSearch: @Sendable () -> Void

    init(onSearch: @escaping @Sendable () -> Void) {
        self.onSearch = onSearch
    }

    func searchPhotos(tags: String) async throws -> [FlickrPhoto] {
        searches.append(tags)
        onSearch()
        return []
    }
}
