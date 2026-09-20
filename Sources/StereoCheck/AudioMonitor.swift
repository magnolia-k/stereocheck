import Combine
import CoreAudio
import Foundation

struct SpeakerInfo: Identifiable, Sendable {
    let id: AudioDeviceID
    let name: String
    let leftChannel: UInt32?   // 物理チャンネル番号（Lに割り当て）
    let rightChannel: UInt32?  // 物理チャンネル番号（Rに割り当て）

    var canSwapChannels: Bool { leftChannel != nil && rightChannel != nil }

    var isSwapped: Bool {
        guard let leftChannel, let rightChannel else { return false }
        return leftChannel > rightChannel
    }

    var channelLabel: String {
        guard let leftChannel, let rightChannel else {
            return "ステレオ設定を取得できません"
        }
        return "L←Ch\(leftChannel)  R←Ch\(rightChannel)"
    }
}

@MainActor
final class AudioMonitor: ObservableObject {
    @Published private(set) var speakers: [SpeakerInfo] = []
    @Published private(set) var defaultDeviceID: AudioDeviceID = 0
    @Published private(set) var errorMessage: String?

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
        defaultDeviceID = fetchDefaultOutputDeviceID()
    }

    // MARK: - Private

    private func startMonitoring() {
        let selectors: [AudioObjectPropertySelector] = [
            kAudioHardwarePropertyDevices,
            kAudioHardwarePropertyDefaultOutputDevice,
        ]
        for selector in selectors {
            var address = AudioObjectPropertyAddress(
                mSelector: selector,
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
    }

    private func fetchDefaultOutputDeviceID() -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
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
        guard let outputChannelCount = outputChannelCount(deviceID), outputChannelCount > 0 else {
            return nil
        }
        let name = deviceName(deviceID) ?? "Unknown"
        let channels = outputChannelCount >= 2 ? preferredStereoChannels(deviceID) : nil
        return SpeakerInfo(
            id: deviceID,
            name: name,
            leftChannel: channels?.left,
            rightChannel: channels?.right
        )
    }

    private func outputChannelCount(_ deviceID: AudioDeviceID) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr,
              size >= UInt32(MemoryLayout<AudioBufferList>.size) else { return nil }

        let ptr = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { ptr.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr) == noErr else { return nil }

        let bufferList = UnsafeMutableAudioBufferListPointer(
            ptr.bindMemory(to: AudioBufferList.self, capacity: 1)
        )
        return bufferList.reduce(0) { $0 + $1.mNumberChannels }
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
        guard let leftChannel = speaker.leftChannel,
              let rightChannel = speaker.rightChannel else {
            errorMessage = "\(speaker.name) はステレオチャンネル設定に対応していません。"
            return
        }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard isPropertySettable(speaker.id, address: &address) else {
            errorMessage = "\(speaker.name) のチャンネル設定は変更できません。"
            return
        }
        var channels: [UInt32] = [rightChannel, leftChannel]
        let size = UInt32(MemoryLayout<UInt32>.size * 2)
        let status = AudioObjectSetPropertyData(speaker.id, &address, 0, nil, size, &channels)
        guard status == noErr else {
            errorMessage = "\(speaker.name) のチャンネル変更に失敗しました（OSStatus: \(status)）。"
            return
        }
        errorMessage = nil
        refresh()
    }

    /// 指定デバイスをデフォルト出力デバイスに設定する
    func setDefaultDevice(_ speaker: SpeakerInfo) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = speaker.id
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let systemObject = AudioObjectID(kAudioObjectSystemObject)
        guard isPropertySettable(systemObject, address: &address) else {
            errorMessage = "再生先を変更できません。"
            return
        }
        let status = AudioObjectSetPropertyData(systemObject, &address, 0, nil, size, &deviceID)
        guard status == noErr else {
            errorMessage = "再生先の変更に失敗しました（OSStatus: \(status)）。"
            return
        }
        errorMessage = nil
        refresh()
    }

    func dismissError() {
        errorMessage = nil
    }

    private func isPropertySettable(
        _ objectID: AudioObjectID,
        address: inout AudioObjectPropertyAddress
    ) -> Bool {
        var isSettable: DarwinBoolean = false
        return AudioObjectIsPropertySettable(objectID, &address, &isSettable) == noErr
            && isSettable.boolValue
    }

    /// Audio MIDI Setupの「チャンネルを使用」に相当。
    /// 戻り値: (Lに割り当てられたチャンネル番号, Rに割り当てられたチャンネル番号)
    /// 正常: (1, 2)、入れ替わり: (2, 1) のような組み合わせ
    private func preferredStereoChannels(_ deviceID: AudioDeviceID) -> (left: UInt32, right: UInt32)? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var channels = [UInt32](repeating: 0, count: 2)
        var size = UInt32(MemoryLayout<UInt32>.size * 2)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &channels) == noErr else {
            return nil
        }
        return (channels[0], channels[1])
    }
}
