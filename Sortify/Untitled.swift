//
//  StatisticsView.swift
//  Sortify
//
//  Created by Michael Wu on 2025/6/30.
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query private var photos: [Photo]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 標題
                Text("統計資訊")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // 統計卡片
                VStack(spacing: 20) {
                    StatCard(
                        title: "保留的相片",
                        count: keptCount,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                    
                    StatCard(
                        title: "刪除的相片",
                        count: deletedCount,
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                    
                    StatCard(
                        title: "總計",
                        count: totalCount,
                        color: .blue,
                        icon: "photo.fill"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 進度條
                if totalCount > 0 {
                    VStack(spacing: 10) {
                        Text("完成進度")
                            .font(.headline)
                        
                        ProgressView(value: Double(totalCount), total: Double(originalPhotoCount))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text("\(totalCount) / \(originalPhotoCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
                
                // 關閉按鈕
                Button("關閉") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 30)
            }
        }
    }
    
    private var keptCount: Int {
        photos.filter { $0.isKept }.count
    }
    
    private var deletedCount: Int {
        photos.filter { !$0.isKept }.count
    }
    
    private var totalCount: Int {
        keptCount + deletedCount
    }
    
    private var originalPhotoCount: Int {
        max(totalCount, 1000) // default value, should be fetched from the photo library
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(count) 張")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Photo.self, inMemory: true)
}
