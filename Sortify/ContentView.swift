//
//  ContentView.swift
//  Sortify
//
//  Created by Michael Wu on 2025/6/30.
//

import SwiftUI
import SwiftData
import Photos

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [Photo] 
    @State private var currentPhotoIndex = 0
    @State private var photoAssets: [PHAsset] = [] // 待處理的相片陣列
    @State private var isPhotoLibraryAuthorized = false
    @State private var showingPermissionAlert = false
    @State private var showingStatistics = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isPhotoLibraryAuthorized {
                    if !photoAssets.isEmpty {
                        PhotoSwipeView(
                            photoAssets: photoAssets,
                            currentIndex: $currentPhotoIndex,
                            onSwipeLeft: { deletePhoto() },
                            onSwipeRight: { keepPhoto() }
                        )
                    } else {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No photos found")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Need Photo Library Permission")
                            .font(.title2)
                            .padding()
                        Button("Authorize Photo Library") {
                            requestPhotoLibraryAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Photo Browser")
            .toolbar {
                if isPhotoLibraryAuthorized && !photoAssets.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Statistics") {
                            showingStatistics = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
        }
        .onAppear {
            checkPhotoLibraryPermission()
        }
        .alert("Need Photo Library Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please open the photo library access permission in the settings to use this feature")
        }
        // .alert("Confirm Delete", isPresented: $showingDeleteConfirmation) {
        //     Button("Delete", role: .destructive) {
        //         performActualDelete()
        //     }
        //     Button("Cancel", role: .cancel) { }
        // } message: {
        //     Text("This operation will permanently delete the photo from the library and cannot be undone.")
        // }
    }
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            isPhotoLibraryAuthorized = true
            loadPhotos()
        case .denied, .restricted:
            isPhotoLibraryAuthorized = false
            showingPermissionAlert = true
        case .notDetermined:
            requestPhotoLibraryAccess()
        @unknown default:
            isPhotoLibraryAuthorized = false
        }
    }
    
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.isPhotoLibraryAuthorized = true
                    self.loadPhotos()
                case .denied, .restricted:
                    self.isPhotoLibraryAuthorized = false
                    self.showingPermissionAlert = true
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        photoAssets = assets
        currentPhotoIndex = 0
    }
    
    // Keep current photo
    private func keepPhoto() {
        guard !photoAssets.isEmpty else {
            print("⚠️ keepPhoto: index out of bounds")
            return
        }
        
        let asset = photoAssets[0]
        print("✅ Keep photo: \(asset.localIdentifier)")
        
        let photo = Photo(
            localIdentifier: asset.localIdentifier,
            timestamp: asset.creationDate ?? Date(),
            isKept: true
        )
        
        modelContext.insert(photo)
        
        // Record the state before removal
        let oldAssetId = asset.localIdentifier
        
        // Remove current photo
        photoAssets.remove(at: 0)
        print("🗑️ After keeping, remaining count: \(photoAssets.count)")
        
        // Add debug info to verify the array state
        // print("Debug(ContentView): photoAssets after keeping:")
        // for (index, asset) in photoAssets.enumerated() {
        //     print("  [\(index)]: \(asset.localIdentifier)")
        // }
        
        // Verify the new photo is different
        if !photoAssets.isEmpty {
            let newAsset = photoAssets[0]
            print("🔍 Verify: new photo: \(newAsset.localIdentifier), same as old photo: \(newAsset.localIdentifier == oldAssetId)")
        }
    }
    
    // Delete current photo
    private func deletePhoto() {
        performActualDelete()
        // showingDeleteConfirmation = true
    }
    
    private func performActualDelete() {
        guard !photoAssets.isEmpty else {
            print("⚠️ deletePhoto: photoAssets is empty")
            return
        }
        
        let asset = photoAssets[0]
        print("❌ Delete photo: \(asset.localIdentifier)")
        
        let photo = Photo(
            localIdentifier: asset.localIdentifier,
            timestamp: asset.creationDate ?? Date(),
            isKept: false
        )
        
        modelContext.insert(photo)
        
        // 實際刪除相簿中的照片
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Successfully deleted photo from library: \(asset.localIdentifier)")
                } else {
                    print("❌ Failed to delete photo: \(error?.localizedDescription ?? "Unknown error")")
                }
                self.photoAssets.remove(at: 0)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Photo.self, inMemory: true)
}
