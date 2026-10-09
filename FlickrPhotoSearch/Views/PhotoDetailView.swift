//
//  PhotoDetailView.swift
//  FlickrPhotoSearch
//
//  Created by Bhargavi M on 10/8/26.
//

import SwiftUI
import UIKit

struct PhotoDetailView: View {
    let photo: FlickrPhoto

    @State private var image: UIImage?
    @State private var imageSize = "Loading…"
    @State private var errorMessage: String?
    @State private var retryCount = 0
    @State private var showShareSheet = false

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()

        if let date = formatter.date(from: photo.published) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: photo.published) else {
            return photo.published
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private var shareText: String {
        """
        \(photo.displayTitle)
        Author: \(photo.author)
        Dimensions: \(imageSize)
        Tags: \(photo.tags)
        Published: \(formattedDate)
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photoSection
                Text(photo.displayTitle)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                detailRow("Dimensions", value: imageSize)
                Text("Pixel dimensions of the downloaded image.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                detailRow("Author", value: photo.author)
                detailRow("Tags", value: photo.tags.isEmpty ? "No tags" : photo.tags)
                detailRow("Published", value: formattedDate)

                Button {
                    showShareSheet = true
                } label: {
                    Label("Share image", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(image == nil)
                .accessibilityHint("Shares the image and photo details")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Photo Details")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: retryCount) {
            await loadPhoto()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image {
                ShareSheet(image: image, text: shareText)
            }
        }
    }

    private var photoSection: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(photo.displayTitle)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                    Button("Retry image") {
                        retryCount += 1
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 180)

            } else {
                ProgressView("Loading image…")
                    .frame(maxWidth: .infinity, minHeight: 180)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    @MainActor
    private func loadPhoto() async {
        errorMessage = nil
        imageSize = "Loading…"

        do {
            let photoData = try await ImageLoader.shared.loadPhoto(from: photo.imageURL)
            try Task.checkCancellation()

            guard let loadedImage = UIImage(data: photoData.data) else {
                throw FlickrError.invalidImage
            }

            var transaction = Transaction()
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                image = loadedImage
                imageSize = "\(photoData.width) × \(photoData.height) pixels"
            }

        } catch {
            guard !Task.isCancelled,
                  !(error is CancellationError) else {
                return
            }
            imageSize = "Unavailable"
            errorMessage = error.localizedDescription
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
    }
    
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
