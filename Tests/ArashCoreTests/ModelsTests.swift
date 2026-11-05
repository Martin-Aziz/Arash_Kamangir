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

    func testHafezGhazalSelectionMatchesCanonicalPoemIdentity() throws {
        // Mirrors Ganjoor's official _cat.json and sh1/sh2 identity fields.
        // Selection uses canonical FullUrl, NOT list position or poem number math.
        let categoryJSON = #"""
        {"Id":24,"Title":"غزلیات","FullUrl":"/hafez/ghazal",
         "ChildCats":[],
         "Poems":[
            {"Id":2130,"Title":"غزل شمارهٔ ۱","FullUrl":"/hafez/ghazal/sh1"},
            {"Id":2131,"Title":"غزل شمارهٔ ۲","FullUrl":"/hafez/ghazal/sh2"}]}
        """#
        let firstJSON = #"""
        {"Id":2130,"Title":"غزل شمارهٔ ۱",
         "FullTitle":"حافظ » غزلیات » غزل شمارهٔ ۱",
         "FullUrl":"/hafez/ghazal/sh1", "Verses":[]}
        """#
        let secondJSON = #"""
        {"Id":2131,"Title":"غزل شمارهٔ ۲",
         "FullTitle":"حافظ » غزلیات » غزل شمارهٔ ۲",
         "FullUrl":"/hafez/ghazal/sh2", "Verses":[]}
        """#
        let decoder = JSONDecoder()
        let category = try decoder.decode(GanjoorCategory.self, from: Data(categoryJSON.utf8))
        let first = try decoder.decode(GanjoorPoem.self, from: Data(firstJSON.utf8))
        let second = try decoder.decode(GanjoorPoem.self, from: Data(secondJSON.utf8))

        let firstRow = try XCTUnwrap(category.poems.first)
        let secondRow = try XCTUnwrap(category.poems.last)
        XCTAssertEqual(firstRow.id, 2130)
        XCTAssertEqual(firstRow.title, "غزل شمارهٔ ۱")
        XCTAssertEqual(try GanjoorPath.poem(firstRow.fullURL), "poets/hafez/ghazal/sh1.json")
        XCTAssertTrue(first.matches(firstRow))
        XCTAssertFalse(second.matches(firstRow))
        XCTAssertTrue(second.matches(secondRow))
        XCTAssertFalse(first.matches(secondRow))
    }

    func testWrongPoemIDIsRejectedEvenWhenURLMatches() throws {
        let row = try JSONDecoder().decode(
            GanjoorEntry.self,
            from: Data(#"{"Id":2130,"Title":"غزل شمارهٔ ۱","FullUrl":"/hafez/ghazal/sh1"}"#.utf8))
        let mismatchedPoem = try JSONDecoder().decode(
            GanjoorPoem.self,
            from: Data(#"{"Id":2131,"Title":"غزل شمارهٔ ۱","FullUrl":"/hafez/ghazal/sh1","Verses":[]}"#.utf8))
        XCTAssertFalse(mismatchedPoem.matches(row))
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


    func testReaderFontsAreIsolatedByAppIdentity() {
        let root = URL(fileURLWithPath: "/tmp/arash-app-support-unit", isDirectory: true)
        let production = GanjoorLibraryLocation.userFontRoot(
            applicationSupport: root, bundleID: GanjoorLibraryLocation.productionBundleID)
        let qa = GanjoorLibraryLocation.userFontRoot(
            applicationSupport: root, bundleID: GanjoorLibraryLocation.qaBundleID)
        XCTAssertNotEqual(production.standardizedFileURL, qa.standardizedFileURL)
        XCTAssertEqual(production.lastPathComponent, "ImportedFonts")
        XCTAssertEqual(qa.lastPathComponent, "ImportedFonts")
        XCTAssertEqual(production.deletingLastPathComponent().lastPathComponent, "ArashKam")
        XCTAssertEqual(qa.deletingLastPathComponent().lastPathComponent, "ArashKamQA")
    }

    func testIsolatedQABundleNeverSharesProductionLibrary() {
        let support = URL(fileURLWithPath: "/tmp/ArashQA-Test-ApplicationSupport", isDirectory: true)
        let production = GanjoorLibraryLocation.defaultRoot(
            applicationSupport: support, bundleID: GanjoorLibraryLocation.productionBundleID)
        let qa = GanjoorLibraryLocation.defaultRoot(
            applicationSupport: support, bundleID: GanjoorLibraryLocation.qaBundleID)
        let commandLine = GanjoorLibraryLocation.defaultRoot(
            applicationSupport: support, bundleID: nil)

        XCTAssertEqual(production.lastPathComponent, "GanjoorData")
        XCTAssertEqual(qa.lastPathComponent, "GanjoorData")
        XCTAssertEqual(production.deletingLastPathComponent().lastPathComponent, "ArashKam")
        XCTAssertEqual(qa.deletingLastPathComponent().lastPathComponent, "ArashKamQA")
        XCTAssertNotEqual(production.standardizedFileURL, qa.standardizedFileURL)
        XCTAssertEqual(commandLine, production)
    }

    func testOfflineInventoryAndSafeDeletion() async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temp) }
        let disk = GanjoorDiskLibrary(root: temp)

        try await disk.save(Data("hafez".utf8), at: "poets/hafez/poet.json")
        try await disk.save(Data("poem".utf8), at: "poets/hafez/ghazal/sh1.json")
        try await disk.save(Data("saadi".utf8), at: "poets/saadi/poet.json")
        try await disk.save(Data("partial".utf8), at: "poets/rumi/poet.json")
        try await disk.markImported("hafez")
        try await disk.markImported("saadi")

        let records = try await disk.offlinePoetRecords()
        XCTAssertEqual(records.map(\.slug), ["hafez", "saadi"])
        XCTAssertEqual(records.first?.fileCount, 2)
        XCTAssertEqual(records.first?.bytes, 9)

        try await disk.removeOfflinePoet("hafez")
        // A second removal is safe if the first already completed.
        try await disk.removeOfflinePoet("hafez")
        let removed = try await disk.exists("poets/hafez/poet.json")
        let other = try await disk.exists("poets/saadi/poet.json")
        let partial = try await disk.exists("poets/rumi/poet.json")
        XCTAssertFalse(removed)
        XCTAssertTrue(other)
        XCTAssertTrue(partial)
        let remaining = try await disk.offlinePoetRecords()
        XCTAssertEqual(remaining.map(\.slug), ["saadi"])
    }

    func testRejectsUnsafeDeletionSlug() async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let disk = GanjoorDiskLibrary(root: temp)
        for invalid in ["../elsewhere", "a/b", "", "..", "x\\y"] {
            do {
                try await disk.removeOfflinePoet(invalid)
                XCTFail("Unsafe slug was accepted: \(invalid)")
            } catch {
                XCTAssertTrue(error is ArchivePathError)
            }
        }
    }

    func testDeletionRejectsSymlinkedPoetDirectoryParent() async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temp) }

        let archive = temp.appendingPathComponent("archive")
        let outside = temp.appendingPathComponent("outside")
        try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: outside.appendingPathComponent("hafez"),
            withIntermediateDirectories: true)
        let protectedFile = outside.appendingPathComponent("hafez/poem.json")
        try Data("keep".utf8).write(to: protectedFile)
        try FileManager.default.createSymbolicLink(
            at: archive.appendingPathComponent("poets"),
            withDestinationURL: outside)

        let disk = GanjoorDiskLibrary(root: archive)
        do {
            try await disk.removeOfflinePoet("hafez")
            XCTFail("Removal followed the symlinked poets directory.")
        } catch {
            XCTAssertTrue(error is ArchivePathError)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: protectedFile.path))
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
