import Foundation

// convert i18n JSON templates to strings files
private func convert(from inputDirectoryURL: URL, to outputDirectory: URL) {
    do {
        print("attempting to get contents of directory at \(inputDirectoryURL)")
        let inputLanguageDirectoryURLs = try FileManager.default.contentsOfDirectory(
            at: inputDirectoryURL,
            includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
            options: []
        )
        for inputLanguageDirectoryURL in inputLanguageDirectoryURLs {
            let language = inputLanguageDirectoryURL.lastPathComponent
            print("attempting to convert \(language)")
            guard let mappedLanguage = map(language: language) else { continue }
            print("found mapping for \(language)")
            
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: inputLanguageDirectoryURL,
                includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                options: []
            )
            for jsonURL in fileURLs where jsonURL.pathExtension == "json" {
                let filename = jsonURL.deletingPathExtension().lastPathComponent
                guard let (mappedFilename, keyStyle) = map(filename: filename) else { continue }
                guard let bundle = bundle(filename: filename) else { continue }
                
                let outputDirectoryURL = outputDirectory
                    .appendingPathComponent(bundle, isDirectory: true)
                    .appendingPathComponent(mappedLanguage + ".lproj", isDirectory: true)

                let outputFileURL = outputDirectoryURL
                    .appendingPathComponent(mappedFilename)
                    .appendingPathExtension("strings")
                
                let strings = try process(url: jsonURL, keyStyle: keyStyle)
                try? FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                
                try strings.write(to: outputFileURL, atomically: true, encoding: .utf8)
            }
        }
    } catch {
        print("error: \(error)")
        exit(1)
    }
}

private func map(language: String) -> String? {
    switch language {
    case "Base.lproj":      return "Base"
    case "an.lproj":        return "an"         // Aragonese
    case "ar.lproj":        return "ar"         // Arabic
    case "be.lproj":        return "be"         // Belarussian
    case "ca.lproj":        return "ca"         // Catalan
    case "ckb.lproj":       return "ckb"        // Sorani (Kurdish)
    case "cs.lproj":        return "cs"         // Czech
    case "cy.lproj":        return "cy"         // Welsh
    case "da.lproj":        return "da"         // Danish
    case "de.lproj":        return "de"         // German
    case "el.lproj":        return "el"         // Greek
    case "en.lproj":        return "en"         // English
    case "en-US.lproj":     return "en-US"      // English (US)
    case "es.lproj":        return "es"         // Spanish
    case "es_AR.lproj":     return "es-AR"      // Spanish (Argentina)
    case "et.lproj":        return "et"         // Estonian
    case "eu.lproj":        return "eu"         // Basque
    case "fi.lproj":        return "fi"         // Finnish
    case "fr.lproj":        return "fr"         // French
    case "gd.lproj":        return "gd"         // Scottish Gaelic
    case "gl.lproj":        return "gl"         // Galician
    case "he.lproj":        return "he"         // Hebrew
    case "hi.lproj":        return "hi"         // Hindi
    case "hu.lproj":        return "hu"         // Hungarian
    case "hy.lproj":        return "hy"         // Armenian
    case "hy-AM.lproj":     return "hy-AM"      // Armenian (Armenia)
    case "id.lproj":        return "id"         // Indonesian
    case "is.lproj":        return "is"         // Icelandic
    case "it.lproj":        return "it"         // Italian
    case "ja.lproj":        return "ja"         // Japanese
    case "kab.lproj":       return "kab"        // Kabyle
    case "kmr.lproj":       return "ku"         // Kurmanji (Kurdish) [intent mapping]
    case "ko.lproj":        return "ko"         // Korean
    case "lt.lproj":        return "lt"         // Lithuanian
    case "lv.lproj":        return "lv"         // Latvian
    case "my.lproj":        return "my"         // Burmese
    case "nl.lproj":        return "nl"         // Dutch
    case "pl.lproj":        return "pl"         // Polish
    case "pt.lproj":        return "pt"         // Portuguese
    case "pt-BR.lproj":     return "pt-BR"      // Portuguese (Brazil)
    case "ro.lproj":        return "ro"         // Romanian
    case "ru.lproj":        return "ru"         // Russian
    case "si.lproj":        return "si"         // Sinhala
    case "sl.lproj":        return "sl"         // Slovenian
    case "sv.lproj":        return "sv"         // Swedish
    case "th.lproj":        return "th"         // Thai
    case "tr.lproj":        return "tr"         // Turkish
    case "uk.lproj":        return "uk"         // Ukranian
    case "vi.lproj":        return "vi"         // Vietnamese
    case "zh-Hans.lproj":   return "zh-Hans"    // Chinese Simplified
    case "zh-Hant.lproj":   return "zh-Hant"    // Chinese Traditional
  
    default:                return nil
    }
}

private func map(filename: String) -> (filename: String, keyStyle: Parser.KeyStyle)? {
    switch filename {
    case "app":             return ("Localizable", .swiftgen)
    case "ios-infoPlist":   return ("infoPlist", .infoPlist)
    default:                return nil
    }
}

private func bundle(filename: String) -> String? {
    switch filename {
    case "app":             return "module"
    case "ios-infoPlist":   return "main"
    default:                return nil
    }
}

private func process(url: URL, keyStyle: Parser.KeyStyle) throws -> String {
    do {
        let data = try Data(contentsOf: url)
        let parser = try Parser(data: data)
        let strings = parser.generateStrings(keyStyle: keyStyle)
        return strings
    } catch {
        throw error
    }
}

// keep path extension and only rename the folder name
private func move(from inputDirectoryURL: URL, to outputDirectoryURL: URL, pathExtension: String) {
    do {
        let inputLanguageDirectoryURLs = try FileManager.default.contentsOfDirectory(
            at: inputDirectoryURL,
            includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
            options: []
        )
        for inputLanguageDirectoryURL in inputLanguageDirectoryURLs {
            let language = inputLanguageDirectoryURL.lastPathComponent
            guard let mappedLanguage = map(language: language) else { continue }
            let outputDirectoryURL = outputDirectoryURL.appendingPathComponent(mappedLanguage + ".lproj", isDirectory: true)

            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: inputLanguageDirectoryURL,
                includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                options: []
            )
            for dictURL in fileURLs where dictURL.pathExtension == pathExtension {
                let filename = dictURL.deletingPathExtension().lastPathComponent
                
                let outputFileURL = outputDirectoryURL.appendingPathComponent(filename).appendingPathExtension(pathExtension)
                try? FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.copyItem(at: dictURL, to: outputFileURL)
            }
        }
    } catch {
        exit(2)
    }
}


let currentFileURL = URL(fileURLWithPath: "\(#file)", isDirectory: false)
let packageRootURL = currentFileURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

let inputDirectoryURL = packageRootURL.appendingPathComponent("input", isDirectory: true)
let outputDirectoryURL = packageRootURL.appendingPathComponent("output", isDirectory: true)
convert(from: inputDirectoryURL, to: outputDirectoryURL)
print("did convert from \(inputDirectoryURL) to \(outputDirectoryURL)")

let moduleDirectoryURL = outputDirectoryURL.appendingPathComponent("module", isDirectory: true)
move(from: inputDirectoryURL, to: moduleDirectoryURL, pathExtension: "stringsdict")
print("did move from \(inputDirectoryURL) to \(moduleDirectoryURL)")

// i18n from "Intents/input" to "Intents/output"
let intentsDirectoryURL = packageRootURL.appendingPathComponent("Intents", isDirectory: true)
let inputIntentsDirectoryURL = intentsDirectoryURL.appendingPathComponent("input", isDirectory: true)
let outputIntentsDirectoryURL = intentsDirectoryURL.appendingPathComponent("output", isDirectory: true)
move(from: inputIntentsDirectoryURL, to: outputIntentsDirectoryURL, pathExtension: "strings")
print("did move from \(inputIntentsDirectoryURL) to \(outputIntentsDirectoryURL)")
