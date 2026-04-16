import XCTest
@testable import Claude_Usage

final class ClaudeCodeSyncServiceTests: XCTestCase {

    let service = ClaudeCodeSyncService.shared

    // MARK: - extractRefreshToken

    func testExtractRefreshToken_validJSON() {
        let json = """
        { "claudeAiOauth": { "accessToken": "access-abc", "refreshToken": "refresh-xyz" } }
        """
        XCTAssertEqual(service.extractRefreshToken(from: json), "refresh-xyz")
    }

    func testExtractRefreshToken_missingRefreshToken_returnsNil() {
        // Minimal credentials JSON with no refreshToken (e.g. regex-extracted path)
        let json = """
        { "claudeAiOauth": { "accessToken": "access-abc" } }
        """
        XCTAssertNil(service.extractRefreshToken(from: json))
    }

    func testExtractRefreshToken_missingOAuthKey_returnsNil() {
        XCTAssertNil(service.extractRefreshToken(from: #"{ "someOtherKey": {} }"#))
    }

    func testExtractRefreshToken_emptyString_returnsNil() {
        XCTAssertNil(service.extractRefreshToken(from: ""))
    }

    func testExtractRefreshToken_invalidJSON_returnsNil() {
        XCTAssertNil(service.extractRefreshToken(from: "not json at all"))
    }

    // MARK: - extractAccessToken

    func testExtractAccessToken_validJSON() {
        let json = """
        { "claudeAiOauth": { "accessToken": "access-abc", "refreshToken": "refresh-xyz" } }
        """
        XCTAssertEqual(service.extractAccessToken(from: json), "access-abc")
    }

    func testExtractAccessToken_missingAccessToken_returnsNil() {
        let json = #"{ "claudeAiOauth": { "refreshToken": "refresh-xyz" } }"#
        XCTAssertNil(service.extractAccessToken(from: json))
    }

    func testExtractAccessToken_missingOAuthKey_returnsNil() {
        XCTAssertNil(service.extractAccessToken(from: #"{ "someOtherKey": {} }"#))
    }
}
