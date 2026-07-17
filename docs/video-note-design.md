# Video Note Design Document

## 1. Architecture Overview
The implementation of Video Notes (Circles) will be an extension of the existing media message system in Element X. It will use a separate recording and processing pipeline to ensure square video output, but will leverage the existing `UploadService` (integrated via `TimelineController`) and `m.video` event type to maintain compatibility with other Matrix clients.

### Data Flow (Life Cycle)
`Composer` (Trigger) $\rightarrow$ `VideoNoteRecorder` $\rightarrow$ `VideoNoteProcessor` $\rightarrow$ `ThumbnailGenerator` $\rightarrow$ `UploadService` $\rightarrow$ `Matrix Server` $\rightarrow$ `Timeline` $\rightarrow$ `VideoNoteRenderer` $\rightarrow$ `AVPlayer`

---

## 2. Component Definitions

### 2.1. Recording & Processing
- **`VideoNoteRecorder`**: 
    - Uses `AVCaptureSession` configured for the front camera.
    - Implements a square crop by adjusting the video output rect or using a fixed aspect ratio.
    - Handles the "hold-to-record" logic.
- **`VideoNoteProcessor`**:
    - Normalizes the recorded video to a fixed resolution (e.g., 480x480).
    - Ensures the format is H.264 MP4.
    - Compresses the video to fit within reasonable size limits.
- **`VideoNoteThumbnailGenerator`**:
    - Extracts a high-quality frame from the center of the video.
    - Crops it to a square to match the video dimensions.

### 2.2. Integration & Upload
- **`VideoNoteUploader`**:
    - A wrapper around `MediaUploadingPreprocessor` and `TimelineController`.
    - Adds the custom metadata flag `org.mychat.video_note: true` to the event content.
    - Ensures the video is sent as a standard `m.video` event.

### 2.3. Display & Playback
- **`VideoNoteRenderer`**:
    - A new SwiftUI View that wraps `VideoRoomTimelineView` or implements its own logic.
    - Applies a `Clipped` circular mask to the video player.
    - Displays a custom progress ring around the circle.
    - Handles the "Play/Pause" state and duration display.
- **`VideoNotePlayer`**:
    - Specialized `AVPlayer` configuration to loop the video and handle the specific autoplay requirements of video notes.

---

## 3. Integration Points

### 3.1. Composer Integration
- **Trigger**: Add a recording button in `ComposerToolbar.swift` (near the voice recording button).
- **State Management**: The `Composer` state will switch to `Recording` mode, showing the `VideoNoteRecordingView`.

### 3.2. Timeline Integration
- **Factory**: Update `RoomTimelineItemFactory.swift` to check for the `org.mychat.video_note` flag in the event content.
- **Item**: Create `VideoNoteRoomTimelineItem` which inherits from `VideoRoomTimelineItem` but carries the specific "circle" identity.
- **View**: Map `VideoNoteRoomTimelineItem` to `VideoNoteRoomTimelineView`.

---

## 4. Technical Specifications
- **Format**: MP4, H.264, AAC.
- **Aspect Ratio**: 1:1 (Square).
- **Max Duration**: 60 seconds.
- **Metadata**: Custom field `org.mychat.video_note` in the event content.
- **Compatibility**: Other clients will see a standard square video.

## 5. New Files to be Created
- `ElementX/Sources/Screens/RoomScreen/ComposerToolbar/View/VideoNoteRecordingButton.swift`
- `ElementX/Sources/Screens/RoomScreen/ComposerToolbar/View/VideoNoteRecordingComposer.swift`
- `ElementX/Sources/Screens/RoomScreen/ComposerToolbar/View/VideoNoteRecordingView.swift`
- `ElementX/Sources/Services/Media/VideoNoteProcessor.swift`
- `ElementX/Sources/Services/Timeline/TimelineItems/Items/Messages/VideoNoteRoomTimelineItem.swift`
- `ElementX/Sources/Screens/Timeline/View/TimelineItemViews/VideoNoteRoomTimelineView.swift`
