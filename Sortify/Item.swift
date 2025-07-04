//
//  Item.swift
//  test1
//
//  Created by Michael Wu on 2025/6/30.
//

import Foundation
import SwiftData
import Photos

@Model
final class Photo {
    var localIdentifier: String
    var timestamp: Date
    var isKept: Bool
    
    init(localIdentifier: String, timestamp: Date, isKept: Bool = true) {
        self.localIdentifier = localIdentifier
        self.timestamp = timestamp
        self.isKept = isKept
    }
}
