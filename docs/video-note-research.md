# Video Note Research Report

## Project Structure Overview
The project follows a modular architecture with a clear separation between UI (Screens), Business Logic (Services/Controllers), and Data/SDK layers (MatrixRustSDK).

### 1. Composer & Message Sending
- **Main Composer View**: `ElementX/Sources/Screens/RoomScreen/ComposerToolbar/View/MessageComposer.swift`
- **Voice Message Components (Reference for Video Notes)**:
    - `VoiceMessageRecordingButton.swift`: The trigger for recording.
    - `VoiceMessageRecordingComposer.swift`: Handles the recording state and logic.
    - `VoiceMessageRecordingView.swift`: The UI for the recording process.
- **Sending Flow**: 
    - The UI triggers a call to `TimelineController.sendVideo(...)` (or `sendVoiceMessage`).
    - `TimelineController` delegates the action to `activeTimeline` (a `TimelineProxyProtocol`), which interacts with the `MatrixRustSDK` to send the event to the server.

### 2. Timeline & Rendering
- **Timeline Item Factory**: `ElementX/Sources/Services/Timeline/TimelineItems/RoomTimelineItemFactory.swift`
    - Responsible for mapping Matrix events to internal `RoomTimelineItemProtocol` objects.
    - Video messages are mapped to `VideoRoomTimelineItem`.
- **Video Message Logic**: `ElementX/Sources/Services/Timeline/TimelineItems/Items/Messages/VideoRoomTimelineItem.swift`
- **Video Message UI**: `ElementX/Sources/Screens/Timeline/View/TimelineItemViews/VideoRoomTimelineView.swift`
    - This is where the actual rendering of the video bubble happens.

### 3. Media Processing & Upload
- **Preprocessing**: `ElementX/Sources/Services/Media/MediaUploadingPreprocessor.swift`
    - Handles resizing, format conversion (e.g., to MP4), and thumbnail generation.
    - `processVideo(at:maxUploadSize:)` is the key method for video handling.
- **Upload Flow**:
    - `MediaUploadPreviewScreenViewModel.swift` coordinates the preprocessing and the subsequent upload via `timelineController`.
    - `TimelineController` then calls the SDK's upload mechanism.

### 4. Key Components Found
| Component | Path | Role |
| :--- | :--- | :--- |
| `MessageComposer` | `ElementX/Sources/Screens/RoomScreen/ComposerToolbar/View/MessageComposer.swift` | Root composer UI |
| `VoiceMessageRecordingButton` | `ElementX/Sources/Screens/RoomScreen/ComposerToolbar/View/VoiceMessageRecordingButton.swift` | Voice record trigger |
| `VideoRoomTimelineView` | `ElementX/Sources/Screens/Timeline/View/TimelineItemViews/VideoRoomTimelineView.swift` | Video bubble renderer |
| `VideoRoomTimelineItem` | `ElementX/Sources/Services/Timeline/TimelineItems/Items/Messages/VideoRoomTimelineItem.swift` | Video item logic |
| `MediaUploadingPreprocessor` | `ElementX/Sources/Services/Media/MediaUploadingPreprocessor.swift` | Media processing engine |
| `TimelineController` | `ElementX/Sources/Services/Timeline/TimelineController/TimelineController.swift` | Orchestrates sending and timeline updates |

## Analysis for Video Notes Implementation
To implement "Circles" (Video Notes), we should:
1. Create a `VideoNoteRecordingButton` similar to `VoiceMessageRecordingButton`.
2. Implement a `VideoNoteRecordingComposer` that uses `AVCaptureSession` for square video recording.
3. Extend `MediaUploadingPreprocessor` or create a specialized `VideoNoteProcessor` to ensure the output is square and compressed.
4. Create a new `VideoNoteRoomTimelineItem` (or extend `VideoRoomTimelineItem`) that includes a custom flag (e.g., `org.mychat.video_note`).
5. Create a `VideoNoteRoomTimelineView` with a circular mask and custom playback controls.
6. Update `RoomTimelineItemFactory` to instantiate `VideoNoteRoomTimelineItem` when the custom flag is present.
