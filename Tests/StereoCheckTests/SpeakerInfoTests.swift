import CoreAudio
import XCTest
@testable import StereoCheck

final class SpeakerInfoTests: XCTestCase {
    func testNormalChannels() {
        let speaker = SpeakerInfo(id: 1, name: "Test", leftChannel: 1, rightChannel: 2)

        XCTAssertTrue(speaker.canSwapChannels)
        XCTAssertFalse(speaker.isSwapped)
        XCTAssertEqual(speaker.channelLabel, "L←Ch1  R←Ch2")
    }

    func testSwappedChannels() {
        let speaker = SpeakerInfo(id: 1, name: "Test", leftChannel: 2, rightChannel: 1)

        XCTAssertTrue(speaker.canSwapChannels)
        XCTAssertTrue(speaker.isSwapped)
    }

    func testUnavailableChannelsAreNotReportedAsNormalStereo() {
        let speaker = SpeakerInfo(id: 1, name: "Mono", leftChannel: nil, rightChannel: nil)

        XCTAssertFalse(speaker.canSwapChannels)
        XCTAssertFalse(speaker.isSwapped)
        XCTAssertEqual(speaker.channelLabel, "ステレオ設定を取得できません")
    }
}
