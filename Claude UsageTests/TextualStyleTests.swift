import XCTest
@testable import Claude_Usage

final class TextualStyleTests: XCTestCase {

    private let renderer = MenuBarIconRenderer()

    // MARK: - formatTimeRemaining

    func testFormatTimeRemaining_NilResetTime() {
        XCTAssertNil(renderer.formatTimeRemaining(resetTime: nil, duration: 5 * 3600))
    }

    func testFormatTimeRemaining_PastResetTime() {
        let past = Date().addingTimeInterval(-60)
        XCTAssertNil(renderer.formatTimeRemaining(resetTime: past, duration: 5 * 3600))
    }

    func testFormatTimeRemaining_MinutesOnly() {
        let resetTime = Date().addingTimeInterval(45 * 60 + 10) // 45m 10s
        let result = renderer.formatTimeRemaining(resetTime: resetTime, duration: 5 * 3600)
        XCTAssertEqual(result, "45m")
    }

    func testFormatTimeRemaining_HoursAndMinutes() {
        let resetTime = Date().addingTimeInterval(3 * 3600 + 12 * 60 + 30) // 3h 12m 30s
        let result = renderer.formatTimeRemaining(resetTime: resetTime, duration: 5 * 3600)
        XCTAssertEqual(result, "3h 12m")
    }

    func testFormatTimeRemaining_HoursOnly() {
        let resetTime = Date().addingTimeInterval(2 * 3600 + 20) // 2h 0m 20s
        let result = renderer.formatTimeRemaining(resetTime: resetTime, duration: 5 * 3600)
        XCTAssertEqual(result, "2h")
    }

    func testFormatTimeRemaining_DaysHoursMinutes() {
        // Add 30s buffer so sub-second test execution doesn't drop us a minute
        let offset: TimeInterval = 2.0 * 86400 + 5.0 * 3600 + 30.0 * 60 + 30
        let resetTime = Date().addingTimeInterval(offset)
        let result = renderer.formatTimeRemaining(resetTime: resetTime, duration: 7 * 86400)
        XCTAssertEqual(result, "2d 5h 30m")
    }

    func testFormatTimeRemaining_DaysOnly() {
        let resetTime = Date().addingTimeInterval(3 * 86400 + 20) // 3d 0h 0m 20s
        let result = renderer.formatTimeRemaining(resetTime: resetTime, duration: 7 * 86400)
        XCTAssertEqual(result, "3d")
    }

    func testFormatTimeRemaining_LessThanOneMinute() {
        let resetTime = Date().addingTimeInterval(30) // 30 seconds
        let result = renderer.formatTimeRemaining(resetTime: resetTime, duration: 5 * 3600)
        XCTAssertEqual(result, "0m")
    }

    func testFormatTimeRemaining_ExactlyOneDay() {
        let resetTime = Date().addingTimeInterval(86400 + 30) // 1d 0h 0m 30s
        let result = renderer.formatTimeRemaining(resetTime: resetTime, duration: 7 * 86400)
        XCTAssertEqual(result, "1d")
    }

    // MARK: - createTextualStyle (single-profile) via createImage

    func testCreateImage_TextualStyle_ProducesNonEmptyImage() {
        let usage = createTestUsage(sessionPct: 23, weekPct: 50, sessionResetOffset: 3600 * 3)
        let config = MetricIconConfig(metricType: .session, isEnabled: true, iconStyle: .textual, order: 0)
        let globalConfig = createGlobalConfig(showTimeMarker: true)

        let image = renderer.createImage(
            for: .session,
            config: config,
            globalConfig: globalConfig,
            usage: usage,
            apiUsage: nil,
            isDarkMode: true,
            colorMode: .multiColor,
            singleColorHex: "#FFFFFF",
            showIconName: false,
            showNextSessionTime: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testCreateImage_TextualStyle_WeekMetric() {
        let usage = createTestUsage(sessionPct: 23, weekPct: 88, weekResetOffset: 86400 * 2)
        let config = MetricIconConfig(metricType: .week, isEnabled: true, iconStyle: .textual, order: 1)
        let globalConfig = createGlobalConfig(showTimeMarker: true)

        let image = renderer.createImage(
            for: .week,
            config: config,
            globalConfig: globalConfig,
            usage: usage,
            apiUsage: nil,
            isDarkMode: false,
            colorMode: .multiColor,
            singleColorHex: "#FFFFFF",
            showIconName: false,
            showNextSessionTime: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testCreateImage_TextualStyle_WithoutTimeMarker_ShorterImage() {
        let usage = createTestUsage(sessionPct: 50, weekPct: 50, sessionResetOffset: 3600 * 2)
        let configWithTime = createGlobalConfig(showTimeMarker: true)
        let configWithoutTime = createGlobalConfig(showTimeMarker: false)
        let metricConfig = MetricIconConfig(metricType: .session, isEnabled: true, iconStyle: .textual, order: 0)

        let imageWith = renderer.createImage(
            for: .session, config: metricConfig, globalConfig: configWithTime,
            usage: usage, apiUsage: nil, isDarkMode: true, colorMode: .multiColor,
            singleColorHex: "#FFFFFF", showIconName: false, showNextSessionTime: false
        )
        let imageWithout = renderer.createImage(
            for: .session, config: metricConfig, globalConfig: configWithoutTime,
            usage: usage, apiUsage: nil, isDarkMode: true, colorMode: .multiColor,
            singleColorHex: "#FFFFFF", showIconName: false, showNextSessionTime: false
        )

        XCTAssertGreaterThan(imageWith.size.width, imageWithout.size.width)
    }

    func testCreateImage_TextualStyle_MonochromeMode() {
        let usage = createTestUsage(sessionPct: 40, weekPct: 60, sessionResetOffset: 3600)
        let config = MetricIconConfig(metricType: .session, isEnabled: true, iconStyle: .textual, order: 0)
        let globalConfig = createGlobalConfig(showTimeMarker: true)

        let image = renderer.createImage(
            for: .session, config: config, globalConfig: globalConfig,
            usage: usage, apiUsage: nil, isDarkMode: true, colorMode: .monochrome,
            singleColorHex: "#FFFFFF", showIconName: false, showNextSessionTime: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testCreateImage_TextualStyle_SingleColorMode() {
        let usage = createTestUsage(sessionPct: 40, weekPct: 60, sessionResetOffset: 3600)
        let config = MetricIconConfig(metricType: .session, isEnabled: true, iconStyle: .textual, order: 0)
        let globalConfig = createGlobalConfig(showTimeMarker: true)

        let image = renderer.createImage(
            for: .session, config: config, globalConfig: globalConfig,
            usage: usage, apiUsage: nil, isDarkMode: false, colorMode: .singleColor,
            singleColorHex: "#FF0000", showIconName: false, showNextSessionTime: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testCreateImage_TextualStyle_PaceMarkerWithPaceStatus() {
        let usage = createTestUsage(sessionPct: 50, weekPct: 50, sessionResetOffset: 3600)
        let globalConfig = createGlobalConfig(showTimeMarker: true, showPaceMarker: true)
        let config = MetricIconConfig(metricType: .session, isEnabled: true, iconStyle: .textual, order: 0)

        let image = renderer.createImage(
            for: .session, config: config, globalConfig: globalConfig,
            usage: usage, apiUsage: nil, isDarkMode: true, colorMode: .multiColor,
            singleColorHex: "#FFFFFF", showIconName: false, showNextSessionTime: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testCreateImage_TextualStyle_PaceMarkerWithNilPaceStatus() {
        let usage = createTestUsage(sessionPct: 10, weekPct: 10, sessionResetOffset: 3600)
        let globalConfig = createGlobalConfig(showTimeMarker: false, showPaceMarker: true)
        let config = MetricIconConfig(metricType: .session, isEnabled: true, iconStyle: .textual, order: 0)

        let image = renderer.createImage(
            for: .session, config: config, globalConfig: globalConfig,
            usage: usage, apiUsage: nil, isDarkMode: true, colorMode: .multiColor,
            singleColorHex: "#FFFFFF", showIconName: false, showNextSessionTime: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    // MARK: - createMultiProfileTextual

    func testMultiProfileTextual_SessionOnly() {
        let usage = createTestUsage(sessionPct: 30, weekPct: 60, sessionResetOffset: 3600)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 30,
            weekPercentage: nil,
            sessionStatus: .safe,
            weekStatus: .safe,
            monochromeMode: false,
            isDarkMode: true,
            usage: usage,
            showTimeMarker: true
        )

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testMultiProfileTextual_SessionAndWeek() {
        let usage = createTestUsage(sessionPct: 23, weekPct: 88,
                                     sessionResetOffset: 3600 * 3,
                                     weekResetOffset: 86400 * 2)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 23,
            weekPercentage: 88,
            sessionStatus: .safe,
            weekStatus: .critical,
            monochromeMode: false,
            isDarkMode: true,
            usage: usage,
            showTimeMarker: true
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testMultiProfileTextual_SessionAndWeek_WiderThanSessionOnly() {
        let usage = createTestUsage(sessionPct: 23, weekPct: 88,
                                     sessionResetOffset: 3600 * 3,
                                     weekResetOffset: 86400 * 2)

        let sessionOnly = renderer.createMultiProfileTextual(
            sessionPercentage: 23, weekPercentage: nil,
            sessionStatus: .safe, weekStatus: .safe,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: true
        )
        let sessionAndWeek = renderer.createMultiProfileTextual(
            sessionPercentage: 23, weekPercentage: 88,
            sessionStatus: .safe, weekStatus: .critical,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: true
        )

        XCTAssertGreaterThan(sessionAndWeek.size.width, sessionOnly.size.width)
    }

    func testMultiProfileTextual_MonochromeMode() {
        let usage = createTestUsage(sessionPct: 50, weekPct: 50, sessionResetOffset: 3600)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 50, weekPercentage: nil,
            sessionStatus: .moderate, weekStatus: .safe,
            monochromeMode: true, isDarkMode: false,
            usage: usage, showTimeMarker: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testMultiProfileTextual_WithPaceMarker() {
        let usage = createTestUsage(sessionPct: 50, weekPct: 50, sessionResetOffset: 3600)
        let pace = PaceStatus.calculate(usedPercentage: 50, elapsedFraction: 0.3)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 50, weekPercentage: 30,
            sessionStatus: .moderate, weekStatus: .safe,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: true,
            sessionPaceStatus: pace, weekPaceStatus: pace, showPaceMarker: true
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testMultiProfileTextual_WithoutTimeMarker_NarrowerImage() {
        let usage = createTestUsage(sessionPct: 50, weekPct: 50,
                                     sessionResetOffset: 3600,
                                     weekResetOffset: 86400)

        let withTime = renderer.createMultiProfileTextual(
            sessionPercentage: 50, weekPercentage: 50,
            sessionStatus: .safe, weekStatus: .safe,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: true
        )
        let withoutTime = renderer.createMultiProfileTextual(
            sessionPercentage: 50, weekPercentage: 50,
            sessionStatus: .safe, weekStatus: .safe,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: false
        )

        XCTAssertGreaterThan(withTime.size.width, withoutTime.size.width)
    }

    func testMultiProfileTextual_UseSystemColor() {
        let usage = createTestUsage(sessionPct: 60, weekPct: 40, sessionResetOffset: 3600)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 60, weekPercentage: 40,
            sessionStatus: .moderate, weekStatus: .safe,
            monochromeMode: false, isDarkMode: true,
            useSystemColor: true,
            usage: usage, showTimeMarker: true
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testMultiProfileTextual_PaceMarkerWithNilPaceStatus() {
        let usage = createTestUsage(sessionPct: 20, weekPct: 30, sessionResetOffset: 3600)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 20, weekPercentage: 30,
            sessionStatus: .safe, weekStatus: .safe,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: true,
            showPaceMarker: true
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testMultiProfileTextual_ZeroPercentage() {
        let usage = createTestUsage(sessionPct: 0, weekPct: 0, sessionResetOffset: 3600)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 0, weekPercentage: 0,
            sessionStatus: .safe, weekStatus: .safe,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    func testMultiProfileTextual_HighPercentage() {
        let usage = createTestUsage(sessionPct: 100, weekPct: 150, sessionResetOffset: 3600)

        let image = renderer.createMultiProfileTextual(
            sessionPercentage: 100, weekPercentage: 150,
            sessionStatus: .critical, weekStatus: .critical,
            monochromeMode: false, isDarkMode: true,
            usage: usage, showTimeMarker: false
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }

    // MARK: - Enum Coverage

    func testMenuBarIconStyle_TextualProperties() {
        let style = MenuBarIconStyle.textual
        XCTAssertEqual(style.displayName, "Textual")
        XCTAssertEqual(style.rawValue, "textual")
        XCTAssertFalse(style.description.isEmpty)
    }

    func testMultiProfileIconStyle_TextualProperties() {
        let style = MultiProfileIconStyle.textual
        XCTAssertEqual(style.displayName, "Textual")
        XCTAssertEqual(style.rawValue, "textual")
        XCTAssertEqual(style.shortNameKey, "multiprofile.style_textual")
        XCTAssertEqual(style.icon, "textformat")
        XCTAssertFalse(style.description.isEmpty)
    }

    func testMenuBarIconStyle_AllCases_ContainsTextual() {
        XCTAssertTrue(MenuBarIconStyle.allCases.contains(.textual))
        XCTAssertEqual(MenuBarIconStyle.allCases.count, 6)
    }

    func testMultiProfileIconStyle_AllCases_ContainsTextual() {
        XCTAssertTrue(MultiProfileIconStyle.allCases.contains(.textual))
        XCTAssertEqual(MultiProfileIconStyle.allCases.count, 5)
    }

    // MARK: - Codable roundtrip

    func testMenuBarIconStyle_Codable_Roundtrip() throws {
        let original = MenuBarIconStyle.textual
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MenuBarIconStyle.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testMultiProfileIconStyle_Codable_Roundtrip() throws {
        let original = MultiProfileIconStyle.textual
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MultiProfileIconStyle.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Helpers

    private func createTestUsage(
        sessionPct: Double,
        weekPct: Double,
        sessionResetOffset: TimeInterval = 5 * 3600,
        weekResetOffset: TimeInterval = 7 * 86400
    ) -> ClaudeUsage {
        ClaudeUsage(
            sessionTokensUsed: Int(sessionPct * 1000),
            sessionLimit: 100_000,
            sessionPercentage: sessionPct,
            sessionResetTime: Date().addingTimeInterval(sessionResetOffset),
            weeklyTokensUsed: Int(weekPct * 10000),
            weeklyLimit: 1_000_000,
            weeklyPercentage: weekPct,
            weeklyResetTime: Date().addingTimeInterval(weekResetOffset),
            opusWeeklyTokensUsed: 0,
            opusWeeklyPercentage: 0,
            sonnetWeeklyTokensUsed: 0,
            sonnetWeeklyPercentage: 0,
            sonnetWeeklyResetTime: nil,
            costUsed: nil,
            costLimit: nil,
            costCurrency: nil,
            overageBalance: nil,
            overageBalanceCurrency: nil,
            lastUpdated: Date(),
            userTimezone: .current
        )
    }

    private func createGlobalConfig(
        showTimeMarker: Bool,
        showPaceMarker: Bool = false
    ) -> MenuBarIconConfiguration {
        MenuBarIconConfiguration(
            colorMode: .multiColor,
            singleColorHex: "#FFFFFF",
            showIconNames: false,
            showRemainingPercentage: false,
            showTimeMarker: showTimeMarker,
            showPaceMarker: showPaceMarker,
            usePaceColoring: false
        )
    }
}
