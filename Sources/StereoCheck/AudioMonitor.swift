import CoreAudio
import Foundation

struct SpeakerInfo: Identifiable, Sendable {
    let id: AudioDeviceID
    let name: String
    let leftChannel: UInt32   // 物理チャンネル番号（Lに割り当て）
    let rightChannel: UInt32  // 物理チャンネル番号（Rに割り当て）

    var isSwapped: Bool { leftChannel > rightChannel }

    var channelLabel: String {
        "L←Ch\(leftChannel)  R←Ch\(rightChannel)"
    }
}

@MainActor
final class AudioMonitor: ObservableObject {
    @Published private(set) var speakers: [SpeakerInfo] = []

    var hasSwapped: Bool {
        speakers.contains { $0.isSwapped }
    }

    init() {
        refresh()
        startMonitoring()
        startPolling()
    }

    private func startPolling() {
        // Core Audioのリスナーで検知できないケースに備えて5秒ごとに補完ポーリング
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    func refresh() {
        speakers = fetchOutputDevices()
    }

    // MARK: - Private

    private func startMonitoring() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main
        ) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    private func fetchOutputDevices() -> [SpeakerInfo] {
        allDeviceIDs().compactMap { speakerInfo(for: $0) }
    }

    private func allDeviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size
        ) == noErr else { return [] }

        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids
        ) == noErr else { return [] }
        return ids
    }

    private func speakerInfo(for deviceID: AudioDeviceID) -> SpeakerInfo? {
        guard hasOutputChannels(deviceID) else { return nil }
        let name = deviceName(deviceID) ?? "Unknown"
        let (left, right) = preferredStereoChannels(deviceID)
        return SpeakerInfo(id: deviceID, name: name, leftChannel: left, rightChannel: right)
    }

    private func hasOutputChannels(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr,
              size >= UInt32(MemoryLayout<AudioBufferList>.size) else { return false }

        let ptr = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { ptr.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr) == noErr else { return false }

        let bufferList = ptr.bindMemory(to: AudioBufferList.self, capacity: 1).pointee
        return bufferList.mNumberBuffers > 0
    }

    private func deviceName(_ deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr else { return nil }

        var name: Unmanaged<CFString>? = nil
        var actualSize = UInt32(MemoryLayout<Unmanaged<CFString>>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &actualSize, &name) == noErr else { return nil }
        return name?.takeRetainedValue() as String?
    }

    /// 指定デバイスのL/Rチャンネル割り当てを入れ替える
    func swapChannels(for speaker: SpeakerInfo) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var channels: [UInt32] = [speaker.rightChannel, speaker.leftChannel]
        let size = UInt32(MemoryLayout<UInt32>.size * 2)
        AudioObjectSetPropertyData(speaker.id, &address, 0, nil, size, &channels)
        refresh()
    }

    /// Audio MIDI Setupの「チャンネルを使用」に相当。
    /// 戻り値: (Lに割り当てられたチャンネル番号, Rに割り当てられたチャンネル番号)
    /// 正常: (1, 2)、入れ替わり: (2, 1) のような組み合わせ
    private func preferredStereoChannels(_ deviceID: AudioDeviceID) -> (left: UInt32, right: UInt32) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var channels = [UInt32](repeating: 0, count: 2)
        var size = UInt32(MemoryLayout<UInt32>.size * 2)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &channels) == noErr else {
            return (1, 2) // 取得できない場合は正常とみなす
        }
        return (channels[0], channels[1])
    }
}
