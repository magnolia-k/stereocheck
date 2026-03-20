import SwiftUI

struct MenuView: View {
    @EnvironmentObject var monitor: AudioMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if monitor.speakers.isEmpty {
                Text("出力デバイスが見つかりません")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                ForEach(monitor.speakers) { speaker in
                    SpeakerRow(speaker: speaker)
                }
            }

            Divider()

            Button("StereoCheck を終了") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .frame(minWidth: 260)
    }
}

struct SpeakerRow: View {
    let speaker: SpeakerInfo
    @EnvironmentObject var monitor: AudioMonitor
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                monitor.swapChannels(for: speaker)
            } label: {
                Image(systemName: speaker.isSwapped
                    ? "exclamationmark.triangle.fill"
                    : "checkmark.circle.fill")
                .foregroundStyle(isHovered ? .white : (speaker.isSwapped ? .orange : .green))
                .font(.system(size: 16))
                .frame(width: 20)
            }
            .buttonStyle(.plain)
            .help(speaker.isSwapped ? "クリックして元に戻す" : "クリックしてL/Rを入れ替える")

            Button {
                monitor.setDefaultDevice(speaker)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(speaker.name)
                                .fontWeight(.medium)
                            if speaker.id == monitor.defaultDeviceID {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.caption)
                            }
                        }
                        Text(speaker.channelLabel)
                            .font(.caption)
                            .foregroundStyle(isHovered ? .white : (speaker.isSwapped ? .orange : .secondary))
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .help("クリックして再生先に設定する")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
        .foregroundStyle(isHovered ? Color.white : Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { isHovered = $0 }
    }
}
