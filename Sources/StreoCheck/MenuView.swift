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

            Button("StreoCheck を終了") { NSApplication.shared.terminate(nil) }
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

    var body: some View {
        HStack(spacing: 10) {
            Button {
                monitor.swapChannels(for: speaker)
            } label: {
                Image(systemName: speaker.isSwapped
                    ? "exclamationmark.triangle.fill"
                    : "checkmark.circle.fill")
                .foregroundStyle(speaker.isSwapped ? .orange : .green)
                .font(.system(size: 16))
                .frame(width: 20)
            }
            .buttonStyle(.plain)
            .help(speaker.isSwapped ? "クリックして元に戻す" : "クリックしてL/Rを入れ替える")

            VStack(alignment: .leading, spacing: 2) {
                Text(speaker.name)
                    .fontWeight(.medium)
                Text(speaker.channelLabel)
                    .font(.caption)
                    .foregroundStyle(speaker.isSwapped ? .orange : .secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
