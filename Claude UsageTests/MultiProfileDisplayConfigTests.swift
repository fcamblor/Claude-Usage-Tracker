import XCTest
@testable import Claude_Usage

final class MultiProfileDisplayConfigTests: XCTestCase {

    // MARK: - Default Values

    func testDefaultConfig() {
        let config = MultiProfileDisplayConfig()
        XCTAssertEqual(config.iconStyle, .concentric)
        XCTAssertTrue(config.showWeek)
        XCTAssertTrue(config.showProfileLabel)
        XCTAssertFalse(config.useSystemColor)
        XCTAssertTrue(config.showTimeMarker)
        XCTAssertTrue(config.showPaceMarker)
        XCTAssertTrue(config.usePaceColoring)
        XCTAssertFalse(config.showRemainingPercentage)
        XCTAssertFalse(config.showActiveProfileIndicator)
        XCTAssertFalse(config.showAllProfilesInPopover)
    }

    func testStaticDefault() {
        let config = MultiProfileDisplayConfig.default
        XCTAssertFalse(config.showAllProfilesInPopover)
    }

    func testExplicitTrue() {
        let config = MultiProfileDisplayConfig(showAllProfilesInPopover: true)
        XCTAssertTrue(config.showAllProfilesInPopover)
    }

    // MARK: - Codable Round-Trip

    func testRoundTripPreservesAllFields() throws {
        var config = MultiProfileDisplayConfig()
        config.showAllProfilesInPopover = true
        config.showActiveProfileIndicator = true
        config.showTimeMarker = false
        config.usePaceColoring = true
        config.showRemainingPercentage = true

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(MultiProfileDisplayConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertTrue(decoded.showAllProfilesInPopover)
        XCTAssertTrue(decoded.showActiveProfileIndicator)
        XCTAssertFalse(decoded.showTimeMarker)
        XCTAssertTrue(decoded.usePaceColoring)
        XCTAssertTrue(decoded.showRemainingPercentage)
    }

    func testRoundTripFalse() throws {
        let config = MultiProfileDisplayConfig()
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(MultiProfileDisplayConfig.self, from: data)

        XCTAssertFalse(decoded.showAllProfilesInPopover)
        XCTAssertEqual(decoded, config)
    }

    // MARK: - Backward Compatibility (missing key)

    func testDecodingWithoutShowAllProfilesKey() throws {
        // Simulate JSON from a version before showAllProfilesInPopover existed
        let json = """
        {
            "iconStyle": "concentric",
            "showWeek": true,
            "showProfileLabel": true,
            "useSystemColor": false,
            "showTimeMarker": true,
            "showPaceMarker": false,
            "usePaceColoring": false,
            "showRemainingPercentage": false,
            "showActiveProfileIndicator": false
        }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(MultiProfileDisplayConfig.self, from: data)

        // Should default to false when key is absent
        XCTAssertFalse(config.showAllProfilesInPopover)
        XCTAssertEqual(config.iconStyle, .concentric)
        XCTAssertTrue(config.showWeek)
    }

    func testDecodingWithShowAllProfilesTrueInJSON() throws {
        let json = """
        {
            "iconStyle": "concentric",
            "showWeek": true,
            "showProfileLabel": true,
            "showAllProfilesInPopover": true
        }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(MultiProfileDisplayConfig.self, from: data)

        XCTAssertTrue(config.showAllProfilesInPopover)
    }

    func testDecodingOldFormatWithMinimalKeys() throws {
        // Oldest possible format — only the 3 original required keys
        let json = """
        {
            "iconStyle": "concentric",
            "showWeek": false,
            "showProfileLabel": false
        }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(MultiProfileDisplayConfig.self, from: data)

        XCTAssertFalse(config.showAllProfilesInPopover)
        XCTAssertFalse(config.showWeek)
        XCTAssertFalse(config.showProfileLabel)
        // All optional bools should fallback to their defaults
        XCTAssertFalse(config.useSystemColor)
        XCTAssertTrue(config.showTimeMarker) // default true
        XCTAssertFalse(config.showPaceMarker)
    }

    // MARK: - Equatable

    func testEqualityDiffersOnNewFlag() {
        var a = MultiProfileDisplayConfig()
        var b = MultiProfileDisplayConfig()
        XCTAssertEqual(a, b)

        a.showAllProfilesInPopover = true
        XCTAssertNotEqual(a, b)

        b.showAllProfilesInPopover = true
        XCTAssertEqual(a, b)
    }
}
