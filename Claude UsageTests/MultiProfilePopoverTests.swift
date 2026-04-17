import XCTest
@testable import Claude_Usage

final class ProfileInitialsTests: XCTestCase {

    func testTwoWordName() {
        XCTAssertEqual(profileInitials(for: "John Doe"), "JD")
    }

    func testThreeWordName() {
        XCTAssertEqual(profileInitials(for: "John Michael Doe"), "JM")
    }

    func testSingleWordName() {
        XCTAssertEqual(profileInitials(for: "Alice"), "AL")
    }

    func testSingleCharacterName() {
        XCTAssertEqual(profileInitials(for: "A"), "A")
    }

    func testEmptyString() {
        XCTAssertEqual(profileInitials(for: ""), "?")
    }

    func testWhitespaceOnly() {
        XCTAssertEqual(profileInitials(for: "   "), "?")
    }

    func testMultipleSpacesBetweenWords() {
        XCTAssertEqual(profileInitials(for: "John   Doe"), "JD")
    }

    func testUnicodeAccents() {
        XCTAssertEqual(profileInitials(for: "Élodie François"), "ÉF")
    }

    func testLowercaseInput() {
        XCTAssertEqual(profileInitials(for: "alice bob"), "AB")
    }
}

final class SortedProfilesTests: XCTestCase {

    private let idA = UUID()
    private let idB = UUID()
    private let idC = UUID()

    private func makeProfile(id: UUID, name: String) -> Profile {
        Profile(id: id, name: name)
    }

    func testActiveProfileComesFirst() {
        let profiles = [
            makeProfile(id: idA, name: "Zebra"),
            makeProfile(id: idB, name: "Alpha"),
        ]
        let result = sortedProfiles(profiles, activeProfileId: idA)
        XCTAssertEqual(result.map(\.id), [idA, idB])
    }

    func testAlphabeticalWithoutActiveProfile() {
        let profiles = [
            makeProfile(id: idA, name: "Charlie"),
            makeProfile(id: idB, name: "Alpha"),
            makeProfile(id: idC, name: "Bravo"),
        ]
        let result = sortedProfiles(profiles, activeProfileId: nil)
        XCTAssertEqual(result.map(\.name), ["Alpha", "Bravo", "Charlie"])
    }

    func testActiveFirstThenAlphabetical() {
        let profiles = [
            makeProfile(id: idA, name: "Charlie"),
            makeProfile(id: idB, name: "Alpha"),
            makeProfile(id: idC, name: "Bravo"),
        ]
        let result = sortedProfiles(profiles, activeProfileId: idC)
        XCTAssertEqual(result.map(\.name), ["Bravo", "Alpha", "Charlie"])
    }

    func testEmptyList() {
        let result = sortedProfiles([], activeProfileId: idA)
        XCTAssertTrue(result.isEmpty)
    }

    func testSingleProfile() {
        let profiles = [makeProfile(id: idA, name: "Solo")]
        let result = sortedProfiles(profiles, activeProfileId: idA)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Solo")
    }

    func testCaseInsensitiveSort() {
        let profiles = [
            makeProfile(id: idA, name: "zebra"),
            makeProfile(id: idB, name: "Alpha"),
        ]
        let result = sortedProfiles(profiles, activeProfileId: nil)
        XCTAssertEqual(result.map(\.name), ["Alpha", "zebra"])
    }
}
