//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//
import Compound
import SwiftUI
import AVKit

struct VideoNoteRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    let timelineItem: VideoNoteRoomTimelineItem
    
    @State private var contentScanningFailure: ContentScanningFailure?
    
    private var hasMediaCaption: Bool {
        timelineItem.content.caption != nil
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: contentScanningFailure == nil ? 4 : 8) {
                ContentScanningView(contentScannerService: context?.contentScannerService,
                                    mediaSource: timelineItem.content.videoInfo.source) {
                    ZStack {
                        thumbnail
                            .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(L10n.commonVideo)
                            .clipShape(Circle())
                            .onTapGesture {
                                context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
                            }

                        CircularVideoPlayer(source: timelineItem.content.videoInfo.source,
                                           mediaProvider: context?.mediaProvider)
                            .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo)
                            .clipShape(Circle())
                            .onTapGesture {
                                context?.send(viewAction: .mediaTapped(itemID: timelineItem.id))
                            }
                    }
                } scanningContent: {
                    placeholder
                        .overlay { ProgressView() }
                        .timelineMediaFrame(imageInfo: timelineItem.content.thumbnailInfo)
                        .clipShape(Circle())
                } unsafeContent: { failure in
                    ContentScanningFailureView(failure: failure)
                }
                
                if let attributedCaption = timelineItem.content.formattedCaption {
                    FormattedBodyText(attributedString: attributedCaption,
                                      trailingReservedSize: timelineItem.trailingReservedSize,
                                      boostFontSize: timelineItem.shouldBoost)
                } else if let caption = timelineItem.content.caption {
                    FormattedBodyText(text: caption,
                                      trailingReservedSize: timelineItem.trailingReservedSize,
                                      boostFontSize: timelineItem.shouldBoost)
                }
            }
            .onPreferenceChange(ContentScanningFailurePreferenceKey.self) { contentScanningFailure = $0 }
        }
    }
    
    @ViewBuilder
    var thumbnail: some View {
        if let thumbnailSource = timelineItem.content.thumbnailInfo?.source {
            LoadableImage(mediaSource: thumbnailSource,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailInfo?.size,
                          mediaProvider: context?.mediaProvider) { imageView in
                imageView
                    .overlay { playIcon }
            } placeholder: {
                placeholder
            }
        } else {
            playIcon
        }
    }
    
    var playIcon: some View {
        CompoundIcon(\.playSolid, size: .medium, relativeTo: .compound.headingLG)
            .foregroundStyle(.compound.iconPrimary)
            .padding(13)
            .background {
                ZStack {
                    Circle().fill(.compound.bgSubtleSecondary)
                    Circle().stroke(.compound.borderInteractiveSecondary)
                }
            }
    }
    
    var placeholder: some View {
        Rectangle()
            .foregroundStyle(timelineItem.isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

struct CircularVideoPlayer: View {
    let source: MediaSourceProxy
    let mediaProvider: MediaProviderProtocol?

    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                Color.clear
            }
        }
        .task {
            await loadVideo()
        }
    }

    private func loadVideo() async {
        guard let mediaProvider = mediaProvider else { return }

        do {
            // Resolve the source to a URL
            let url = try await mediaProvider.resolveURL(for: source)
            let playerItem = AVPlayerItem(url: url)

            // Setup looping
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                player?.seek(to: .zero)
                player?.play()
            }

            let player = AVPlayer(playerItem: playerItem)
            player.isMuted = true
            self.player = player
        } catch {
            MXLog.error("Failed to load video note: \(error)")
        }
    }
}

struct VideoNoteRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20.0) {
                VideoNoteRoomTimelineView(timelineItem: makeTimelineItem())
                VideoNoteRoomTimelineView(timelineItem: makeTimelineItem(caption: "Circular video note! ⭕️"))
            }
        }
        .environmentObject(viewModel.context)
        .environment(\.timelineContext, viewModel.context)
        .previewLayout(.fixed(width: 390, height: 975))
        .padding(.bottom, 20)
    }
    
    private static func makeTimelineItem(caption: String? = nil) -> VideoNoteRoomTimelineItem {
        VideoNoteRoomTimelineItem(id: .randomEvent,
                                  timestamp: .mock,
                                  isOutgoing: false,
                                  isEditable: false,
                                  canBeRepliedTo: true,
                                  sender: .init(id: "Bob"),
                                  content: .init(filename: "videonote.mp4",
                                                 caption: caption,
                                                 videoInfo: .mockVideo,
                                                 thumbnailInfo: .mockVideoThumbnail,
                                                 blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"))
    }
}
