import Foundation
import XCTest
@testable import ArashCore

final class ModelsTests: XCTestCase {
    func testOfficialManifestDecodes() throws {
        let json = #"{"SchemaVersion":4,"GeneratedAtUtc":"2026-10-24T05:42:55Z","Poets":[{"Id":2,"Nickname":"حافظ","FullUrl":"/hafez"}]}"#
        let manifest = try JSONDecoder().decode(GanjoorManifest.self, from: Data(json.utf8))
        XCTAssertEqual(manifest.schemaVersion, 4)
        XCTAssertEqual(manifest.poets[0].slug, "hafez")
    }

    func testOfficialCategoryDecodes() throws {
        let json = #"{"Id":9,"Title":"حافظ","FullUrl":"/hafez","ChildCats":[{"Id":24,"Title":"غزلیات","FullUrl":"/hafez/ghazal"}],"Poems":[]}"#
        let category = try JSONDecoder().decode(GanjoorCategory.self, from: Data(json.utf8))
        XCTAssertEqual(category.childCategories.count, 1)
        XCTAssertEqual(try GanjoorPath.category(category.childCategories[0].fullURL),
                       "poets/hafez/ghazal/_cat.json")
    }

    func testVerseGroupingAndOrder() throws {
        let json = #"{"Id":2130,"Title":"غزل شماره ۱","FullUrl":"/hafez/ghazal/sh1","Verses":[{"VOrder":2,"Position":"Left","Text":"دوم","CoupletIndex":0},{"VOrder":1,"Position":"Right","Text":"اول","CoupletIndex":0},{"VOrder":3,"Position":"Single","Text":"سوم","CoupletIndex":1}]}"#
        let poem = try JSONDecoder().decode(GanjoorPoem.self, from: Data(json.utf8))
        XCTAssertEqual(poem.plainText, "اول\nدوم\nسوم")
        XCTAssertEqual(poem.readingGroups.map(\.verses.count), [2, 1])
    }

    func testRejectsUnsafeOrEscapingPaths() {
        for value in ["//evil.test/file", "/hafez/../file", "/hafez/%2e%2e/file",
                      "https://bad.test/a", "/hafez/hello?query=1", "/hafez//ghazal"] {
            XCTAssertThrowsError(try GanjoorPath.category(value), value)
        }
        XCTAssertFalse(GanjoorPath.isSafeRelative("../outside"))
        XCTAssertFalse(GanjoorPath.isSafeRelative("poets//x"))
        XCTAssertTrue(GanjoorPath.isSafeRelative("poets/hafez/ghazal/sh1.json"))
    }

    func testPersianCharacterVariants() {
        XCTAssertTrue(PersianNormalizer.contains("كیست در جهان", query: "کیست"))
        XCTAssertTrue(PersianNormalizer.contains("زِ یـار", query: "ز یار"))
    }

    func testOfflineStorageAndCompletionMarker() async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temp) }
        let disk = GanjoorDiskLibrary(root: temp)
        try await disk.save(Data(#"{"Id":2,"Nickname":"حافظ","FullUrl":"/hafez"}"#.utf8),
                            at: "poets/hafez/poet.json")
        let exists = try await disk.exists("poets/hafez/poet.json")
        XCTAssertTrue(exists)
        try await disk.markImported("hafez")
        let imported = try await disk.importedPoetSlugs()
        XCTAssertEqual(imported, ["hafez"])
    }
}
