# FlickrPhotoSearch
A SwiftUI iPhone app for searching photos using Flickr’s public feed.
# Features
Search photos by a single word or comma-separated words.
Debounce search input to avoid unnecessary requests.
Show search results in a photo grid.
Show the selected photo with its title, dimensions, author, tags, and published date.
Handles loading, empty results, and errors.
Allow users to retry failed requests.
Share photos with their metadata.
Support landscape and VoiceOver.
# Implementation
The app follows MVVM:
- Model: Defines the photo data from Flickr.
- View: Shows the search bar, photo grid, and detail screen.
- ViewModel: Handles searches, results, and UI state.
- Networking: Loads photos and image data from Flickr.
# API
https://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1&tags=porcupine
# Tests
Unit tests verify that:
- Successful searches return photos.
- Failed searches show an error.
- Empty input clears the results.
- Clearing the search field removes results immediately.
- Debounce sends only the latest search text.
- Search requests wait for the debounce interval.
