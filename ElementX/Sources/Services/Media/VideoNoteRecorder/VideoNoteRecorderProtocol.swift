//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

nonisolated enum VideoNoteRecorderError: Error, Equatable {
    case unsupportedVideoFormat
    case captureSessionFailure
    case fileCreationFailure
    case interrupted
    case recordingCancelled
    case permissionNotGranted
}

nonisolated enum VideoNoteRecorderAction {
    case didStartRecording
    case didStopRecording
    case didFailWithError(error: VideoNoteRecorderError)
}

nonisolated protocol VideoNoteRecorderProtocol: AnyObject, Sendable {
    var actions: AnyPublisher<VideoNoteRecorderAction, Never> { get }
    var currentTime: TimeInterval { get }
    var isRecording: Bool { get }
    var videoFileURL: URL? { get }
    
    func record(videoFileURL: URL) async
    func stopRecording() async
    func deleteRecording() async
}

// sourcery: AutoMockable
extension VideoNoteRecorderProtocol { }
