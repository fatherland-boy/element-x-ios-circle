//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit

enum VideoNoteRecordingState {
    case recording
    case stopped
    case error
}

class VideoNoteRecorderState: ObservableObject, Identifiable {
    let id = UUID()

    @Published private(set) var recordingState: VideoNoteRecordingState = .stopped
    @Published private(set) var duration = 0.0

    weak var videoRecorder: VideoNoteRecorderProtocol?
    private var cancellables: Set<AnyCancellable> = []
    private var displayLink: CADisplayLink?

    func attachVideoRecorder(_ videoRecorder: VideoNoteRecorderProtocol) {
        recordingState = .stopped
        self.videoRecorder = videoRecorder
        subscribeToVideoRecorder(videoRecorder)
        if videoRecorder.isRecording {
            recordingState = .recording
            startPublishUpdates()
        }
    }

    func detachVideoRecorder() async {
        if let videoRecorder, videoRecorder.isRecording {
            await videoRecorder.stopRecording()
        }
        stopPublishUpdates()
        cancellables = []
        videoRecorder = nil
        recordingState = .stopped
    }

    func reportError() {
        recordingState = .error
    }

    // MARK: - Private

    private func subscribeToVideoRecorder(_ videoRecorder: VideoNoteRecorderProtocol) {
        videoRecorder.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else {
                    return
                }
                self.handleVideoRecorderAction(action)
            }
            .store(in: &cancellables)
    }

    private func handleVideoRecorderAction(_ action: VideoNoteRecorderAction) {
        switch action {
        case .didStartRecording:
            startPublishUpdates()
            recordingState = .recording
        case .didStopRecording:
            stopPublishUpdates()
            recordingState = .stopped
        case .didFailWithError:
            stopPublishUpdates()
            recordingState = .stopped
        }
    }

    private func startPublishUpdates() {
        if displayLink != nil {
            stopPublishUpdates()
        }
        displayLink = CADisplayLink(target: self, selector: #selector(publishUpdate))
        displayLink?.preferredFrameRateRange = .init(minimum: 30, maximum: 60)
        displayLink?.add(to: .current, forMode: .common)
    }

    // periphery:ignore:parameters displayLink - required for objc selector
    @objc private func publishUpdate(displayLink: CADisplayLink) {
        if let currentTime = videoRecorder?.currentTime {
            duration = currentTime
        }
    }

    private func stopPublishUpdates() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

extension VideoNoteRecorderState: Equatable {
    nonisolated static func == (lhs: VideoNoteRecorderState, rhs: VideoNoteRecorderState) -> Bool {
        lhs.id == rhs.id
    }
}
