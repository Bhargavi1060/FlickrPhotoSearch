//
//  PhotoSearchViewModel.swift
//  FlickrPhotoSearch
//
//  Created by Bhargavi M on 10/8/26.
//

import Foundation
import Combine

@MainActor
final class PhotoSearchViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published var searchText = ""
    @Published private(set) var photos: [FlickrPhoto] = []
    @Published private(set) var state: State = .idle

    private let service: any FlickrPhotoService
    private var searchSubscription: AnyCancellable?
    private var searchTask: Task<Void, Never>?
    private var searchNumber = 0

    init(service: any FlickrPhotoService = FlickrService()) {
        self.service = service
        observeSearchText()
    }

    deinit {
        searchTask?.cancel()
    }

    private func observeSearchText() {
        searchSubscription = $searchText
            .dropFirst()
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] text in
                self?.cancelCurrentSearch()

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self?.photos = []
                    self?.state = .idle
                }
            })
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.startSearch(text)
            }
    }

    func retry() {
        cancelCurrentSearch()
        startSearch(searchText)
    }

    private func cancelCurrentSearch() {
        searchNumber += 1
        searchTask?.cancel()
        searchTask = nil
    }

    private func startSearch(_ text: String) {
        searchTask = Task { [weak self] in
            await self?.search(text)
        }
    }

    func search(_ text: String) async {
        searchNumber += 1
        let currentSearch = searchNumber
        let tags = text
            .split(separator: ",")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter {
                !$0.isEmpty
            }
            .joined(separator: ",")

        photos = []

        guard !tags.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        do {
            let results = try await service.searchPhotos(tags: tags)
            try Task.checkCancellation()
            
            guard currentSearch == searchNumber else {
                return
            }
            photos = results
            state = .loaded
        } catch {
            guard currentSearch == searchNumber,
                  !Task.isCancelled,
                  !(error is CancellationError) else {
                return
            }
            state = .failed(errorMessage(for: error))
        }
    }

    private func errorMessage(for error: Error) -> String {
        if error is DecodingError {
            return "The photo response could not be read. Please try again."
        }

        if let error = error as? URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "Check your internet connection and try again."
            case .timedOut:
                return "The request timed out. Please try again."
            default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
