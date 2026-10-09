//
//  PhotoGridItemView.swift
//  FlickrPhotoSearch
//
//  Created by Bhargavi M on 10/8/26.
//

import SwiftUI

struct PhotoGridItemView: View {
    let photo: FlickrPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    GeometryReader { geometry in
                        AsyncImage(url: photo.imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    }
                }
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .allowsHitTesting(false)

            Text(photo.displayTitle)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(photo.displayTitle)
    }
}
