//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Foundation
import UIKit

protocol VideoNoteProcessorProtocol: AnyObject, Sendable {
    func processVideo(at url: URL, maxUploadSize: Int64) async throws -> URL
    func generateThumbnail(from url: URL) async throws -> URL
    func extractVideoInfo(from url: URL) async throws -> MatrixRustSDK.VideoInfo
}

final class VideoNoteProcessor: VideoNoteProcessorProtocol {
    private let outputSize = CGSize(width: 480, height: 480)
    
    func processVideo(at url: URL, maxUploadSize: Int64) async throws -> URL {
        let asset = AVAsset(url: url)
        
        // Create a composition to handle the cropping
        let composition = AVMutableComposition()
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw NSError(domain: "VideoNoteProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video)
        try compositionVideoTrack?.insertTimeRange(CMRange(start: .zero, duration: videoTrack.timeRange.duration), from: videoTrack, at: .zero)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = outputSize
        videoComposition.frameDuration = CMTime.frameDuration(withName: .tv60)
        
        // Create a layer instruction to center-crop the video to a square
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        let trackSize = videoTrack.naturalSize
        let ratio = trackSize.width / trackSize.height
        
        var cropRect = CGRect.zero
        if ratio > 1 {
            // Landscape: crop sides
            let side = trackSize.height
            cropRect = CGRect(x: (trackSize.width - side) / 2, y: 0, width: side, height: side)
        } else {
            // Portrait: crop top/bottom
            let side = trackSize.width
            cropRect = CGRect(x: 0, y: (trackSize.height - side) / 2, width: side, height: side)
        }
        
        // The transform should scale the cropRect to fit the outputSize
        let scale = outputSize.width / cropRect.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        instruction.setTransform(transform, at: .zero)
        
        videoComposition.layerInstructions = [instruction]
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        guard let exportSession = AVAssetExportSession(asset: composition, preset: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "VideoNoteProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"])
        }
        
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
        
        if exportSession.status == .failed {
            throw NSError(domain: "VideoNoteProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: exportSession.error?.localizedDescription ?? "Export failed"])
        }
        
        return outputURL
    }
    
    func generateThumbnail(from url: URL) async throws -> URL {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesDefaultMediaServicePressureAll = false
        
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        let cgImage = try await generator.image(at: time)
        
        // Crop the CGImage to a square
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let side = min(width, height)
        let cropRect = CGRect(x: (width - side) / 2, y: (height - side) / 2, width: side, height: side)
        
        guard let croppedImage = cgImage.cropping(to: cropRect) else {
            throw NSError(domain: "VideoNoteProcessor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not crop thumbnail"])
        }
        
        let uiImage = UIImage(cgImage: croppedImage)
        let thumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "VideoNoteProcessor", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not encode thumbnail to JPEG"])
        }
        
        try data.write(to: thumbnailURL)
        return thumbnailURL
    }
    
    func extractVideoInfo(from url: URL) async throws -> MatrixRustSDK.VideoInfo {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "VideoNoteProcessor", code: 6, userInfo: [NSLocalizedDescriptionKey: "No video track found for metadata extraction"])
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? UInt64 ?? 0
        
        return MatrixRustSDK.VideoInfo(duration: duration,
                                       width: UInt64(naturalSize.width),
                                       height: UInt64(naturalSize.height),
                                       fileSize: fileSize)
    }
}

extension VideoNoteProcessor: Sendable { }
