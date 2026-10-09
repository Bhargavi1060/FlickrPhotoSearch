//
//  PhotoSearchView.swift
//  FlickrPhotoSearch
//
//  Created by Bhargavi M on 10/8/26.
//

import SwiftUI

struct PhotoSearchView: View {
    @StateObject private var viewModel = PhotoSearchViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var columns: [GridItem] {
        let column = GridItem(.flexible(), spacing: 12, alignment: .top)
        return dynamicTypeSize.isAccessibilitySize
            ? [column]
            : [column, column]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Flickr Search")
            .navigationDestination(for: FlickrPhoto.self) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search tags: forest, bird", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Search Flickr by tags")
                .accessibilityHint("Enter one tag or comma-separated tags")

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(.secondary)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, viewModel.searchText.isEmpty ? 12 : 0)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            message("Find photos", subtitle: "Type a single or multiple comma-separated words.")
        case .loading:
            ProgressView("Searching…")
        case .loaded:
            if viewModel.photos.isEmpty {
                message("No matched results found", subtitle: "Try with valid search criteria.")
            } else {
                photoGrid
            }
        case .failed(let error):
            VStack(spacing: 16) {
                message("Couldn't load photos", subtitle: error)
                Button("Retry") {
                    viewModel.retry()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.photos) { photo in
                    NavigationLink(value: photo) {
                        PhotoGridItemView(photo: photo)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel(photo.displayTitle)
                    .accessibilityHint("Opens photo details")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func message(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
