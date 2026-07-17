//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Combine
import Foundation

final class VideoNoteRecorder: NSObject, VideoNoteRecorderProtocol {
    private let captureSession = AVCaptureSession()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let actionsSubject = PassthroughSubject<VideoNoteRecorderAction, Never>()

    var actions: AnyPublisher<VideoNoteRecorderAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private(set) var currentTime: TimeInterval = 0
    private(set) var isRecording = false
    private(set) var videoFileURL: URL?

    private var timer: Timer?

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        captureSession.beginConfiguration()

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput.init(device: videoDevice) else {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
        }

        captureSession.commitConfiguration()
    }

    func record(videoFileURL: URL) async {
        guard !isRecording else { return }

        // Delete existing file if necessary
        try? FileManager.default.removeItem(at: videoFileURL)
        self.videoFileURL = videoFileURL

        captureSession.startRunning()

        movieFileOutput.startRecording(to: videoFileURL, recordingCompletionHandler: { [weak self] (url, error) in
            guard let self = self else { return }

            if let error = error {
                self.actionsSubject.send(.didFailWithError(error: .fileCreationFailure))
            } else {
                self.actionsSubject.send(.didStopRecording)
            }
        })

        isRecording = true
        currentTime = 0
        startTimer()
        actionsSubject.send(.didStartRecording)
    }

    func stopRecording() async {
        guard isRecording else { return }

        movieFileOutput.stopRecording()
        stopTimer()
        isRecording = false
    }

    func deleteRecording() async {
        if let url = videoFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        videoFileURL = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.currentTime += 0.1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension VideoNoteRecorder: Sendable {}
