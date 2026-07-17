//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI
import AVFoundation

struct VideoNoteRecordingView: View {
    @ObservedObject var recorderState: VideoNoteRecorderState

    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return dateFormatter
    }()

    private var timeLabelContent: String {
        Self.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: recorderState.duration))
    }

    var body: some View {
        HStack(spacing: 8) {
            VideoNoteRecordingBadge()
                .frame(width: 8, height: 8)

            Text(timeLabelContent)
                .lineLimit(1)
                .font(.compound.bodySMSemibold)
                .foregroundColor(.compound.textSecondary)
                .monospacedDigit()
                .fixedSize()

            // Placeholder for Camera Preview
            // In a real implementation, this would be a view that hosts the AVCaptureVideoPreviewLayer
            Circle()
                .fill(Color.compound.bgCanvasDefault)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "video.fill")
                        .foregroundColor(.compound.textSecondary)
                )
        }
        .padding(.leading, 2)
        .padding(.trailing, 8)
    }
}

private struct VideoNoteRecordingBadge: View {
    @State private var opacity: CGFloat = 0

    var body: some View {
        Circle()
            .foregroundColor(.red)
            .opacity(opacity)
            .onAppear {
                withElementAnimation(.easeOut(duration: 1).repeatForever(autoreverses: true)) {
                    opacity = 1
                }
            }
    }
}

struct VideoNoteRecordingView_Previews: PreviewProvider, TestablePreview {
    static let recorderState = VideoNoteRecorderState()

    static var previews: some View {
        VideoNoteRecordingView(recorderState: recorderState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
