//
//  PhotoSwipeView.swift
//  Sortify
//
//  Created by Michael Wu on 2025/6/30.
//

import SwiftUI
import Photos

struct PhotoSwipeView: View {
    let photoAssets: [PHAsset]
    @Binding var currentIndex: Int
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var currentImage: UIImage?
    @State private var nextImage: UIImage?  // next photo
    @State private var isLoading = true
    @State private var currentRequestId = 0
    @State private var nextRequestId = 0  // add: next request ID
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // background: next photo (shrink and blur)
                if let nextImage = nextImage {
                    Image(uiImage: nextImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: -50)  // 上移 50 點
                        .scaleEffect(0.9)  // shrink to 90%
                        .blur(radius: 3)  // add blur effect
                        .opacity(0.3)  // reduce opacity
                }
                
                // foreground: current photo
                if let image = currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: -50)  // 上移 50 點
                        .offset(dragOffset)
                        .scaleEffect(1.0 + abs(dragOffset.width) / 1000)
                        .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    handleSwipe(value: value, geometry: geometry)
                                }
                        )
                        
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                        .offset(y: -50)  // 載入指示器也上移
                }
                
                // Swipe Indicator
                VStack {
                    Spacer()
                    HStack {
                        if dragOffset.width > 50 {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                Text("Keep")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .opacity(min(Double(dragOffset.width) / 100.0, 1.0))
                        }
                        
                        Spacer()
                        
                        if dragOffset.width < -50 {
                            VStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                Text("Delete")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            .opacity(min(Double(abs(dragOffset.width)) / 100.0, 1.0))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                }
                
                // Progress Indicator
                VStack {
                    HStack {
                        Text("\(currentIndex + 1) / \(photoAssets.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            loadCurrentImage()
            loadNextImage()  // add: load next image
        }
        .onChange(of: photoAssets) { newPhotoAssets in
            print("🔄 Debug(PhotoSwipeView): new photoAssets array:")
            for (index, asset) in newPhotoAssets.enumerated() {
                print("  [\(index)]: \(asset.localIdentifier)")
            }
            
            // use the new photoAssets parameter directly
            currentImage = nil
            nextImage = nil  // add: clear next image
            currentRequestId += 1
            nextRequestId += 1  // add: reset next request ID
            
            // load the image using the new photoAssets parameter
            loadImageFromAssets(newPhotoAssets)
            loadNextImageFromAssets(newPhotoAssets)  // add: load next image
        }
    }
    
    // add: load next image
    private func loadNextImage() {
        loadNextImageFromAssets(photoAssets)
    }
    
    private func loadNextImageFromAssets(_ assets: [PHAsset]) {
        guard assets.count > 1 else {
            // if there is no next image, clear background
            nextImage = nil
            return
        }
        
        let nextAsset = assets[1] // load the second photo as background
        let requestId = nextRequestId + 1
        nextRequestId = requestId
        
        print("📸 Load next photo: \(nextAsset.localIdentifier), request ID: \(requestId)")
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: nextAsset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            DispatchQueue.main.async {
                // Only update UI if this is still the latest request
                if requestId == self.nextRequestId {
                    if let image = image {
                        self.nextImage = image
                        print("✅ Next photo loaded successfully: identifier: \(nextAsset.localIdentifier), request ID: \(requestId)")
                    } else {
                        print("❌ Next photo load failed: request ID: \(requestId)")
                    }
                } else {
                    print("🔄 Ignoring outdated next photo request: \(requestId), current: \(self.nextRequestId)")
                }
            }
        }
    }
    
    private func loadImageFromAssets(_ assets: [PHAsset]) {
        guard !assets.isEmpty else {
            print("⚠️ photoAssets is empty")
            return
        }
        
        let asset = assets[0] // always load the first photo
        let requestId = currentRequestId + 1  // Generate new request ID
        currentRequestId = requestId
        
        print("📸 Load photo: \(asset.localIdentifier), request ID: \(requestId)")
        print("📸 Debug(PhotoSwipeView): using provided assets array:")
        for (index, asset) in assets.enumerated() {
            print("  [\(index)]: \(asset.localIdentifier)")
        }
        
        isLoading = true
        currentImage = nil
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            DispatchQueue.main.async {
                // Only update UI if this is still the latest request
                if requestId == self.currentRequestId {
                    if let image = image {
                        self.currentImage = image
                        print("✅ Photo loaded successfully: identifier: \(asset.localIdentifier), request ID: \(requestId)")
                    } else {
                        print("❌ Photo load failed: request ID: \(requestId)")
                    }
                    self.isLoading = false
                } else {
                    print("🔄 Ignoring outdated request: \(requestId), current: \(self.currentRequestId)")
                }
            }
        }
    }
    
    private func loadCurrentImage() {
        loadImageFromAssets(photoAssets)
    }
    
    private func handleSwipe(value: DragGesture.Value, geometry: GeometryProxy) {
        guard !isAnimating else { return }  // prevent duplicate animation
        
        let threshold = geometry.size.width * 0.3
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        if abs(value.translation.width) > threshold || abs(velocity) > 500 {
            isAnimating = true
            
            if value.translation.width > 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dragOffset = CGSize(width: geometry.size.width * 1.5, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.onSwipeRight()
                    self.dragOffset = .zero
                    self.isAnimating = false
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dragOffset = CGSize(width: -geometry.size.width * 1.5, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.onSwipeLeft()
                    self.dragOffset = .zero
                    self.isAnimating = false
                }
            }
        } else {
            withAnimation(.spring()) {
                dragOffset = .zero
            }
        }
    }
}

#Preview {
    PhotoSwipeView(
        photoAssets: [],
        currentIndex: .constant(0),
        onSwipeLeft: {},
        onSwipeRight: {}
    )
}
