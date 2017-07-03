//
//  main.swift
//  iosOTAGenerator
//
//  Created by kojiba on 14.04.17.
//  Copyright © 2017 kojiba. All rights reserved.
//

import Foundation

var configFilePath = ""
var ipaPath = ""
var htmlPath = ""
var buildNumber = ""

func createManifest(url: String, appName: String, bundleId: String, bundleVersion: String) -> String {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" +
            "<plist version=\"1.0\">" +
            "<dict>" +
            "<key>items</key>" +
            "<array>" +
            "<dict>" +
            "<key>assets</key>" +
            "<array>" +
            "<dict>" +
            "<key>kind</key>" +
            "<string>software-package</string>" +
            "<key>url</key>" +
            "<string>\(url)</string>" +
            "</dict>" +
            "</array>" +
            "<key>metadata</key>" +
            "<dict>" +
            "<key>bundle-identifier</key>" +
            "<string>\(bundleId)</string>" +
            "<key>bundle-version</key>" +
            "<string>\(bundleVersion)</string>" +
            "<key>kind</key>" +
            "<string>software</string>" +
            "<key>title</key>" +
            "<string>\(appName)</string>" +
            "</dict>" +
            "</dict>" +
            "</array>" +
            "</dict>" +
            "</plist>"
}

func writeManifestToPath(manifestUrl: URL, webUrl: String, appName: String, bundleId: String, bundleVersion: String) throws {
    let manifestText = createManifest(url: webUrl,
            appName: appName,
            bundleId: bundleId,
            bundleVersion: bundleVersion)

    try manifestText.write(to: manifestUrl, atomically: false, encoding: String.Encoding.utf8)
}

func indexHtmlFile(manifestUrl: String, appName: String, version: String) -> String {
    return "<a href=\"itms-services://?action=download-manifest&url=\(manifestUrl)\">\(appName) v\(version) Build: \(buildNumber)</a>"
}

let htmlTag = "OTA_URLS_TABLE"

func appendLinkInHTML(htmlPath: String, linkToNewBuild: String) {
    let url = URL(fileURLWithPath: htmlPath)

    if let text = try? String(contentsOf: url, encoding: .utf8) {

        let divToReplace = "<div id=\"\(htmlTag)\">"
        let replaced = text.replacingOccurrences(of: divToReplace, with: divToReplace + linkToNewBuild + "\n<br><br>\n")

        try? replaced.write(to: url, atomically: false, encoding: String.Encoding.utf8)
    }
}

func moveToFolderAndCreateFiles(fileName: String, webUrl: String, appName: String, bundleId: String, bundleVersion: String, htmlPath: String) {
    let fileUrl = URL(fileURLWithPath: fileName)

    let filename = fileUrl.pathComponents.last!
    let filenameWithoutExt = filename.components(separatedBy: ".")[0]

    let moveToUrl = fileUrl.deletingLastPathComponent().appendingPathComponent(filenameWithoutExt)

    let fileManager = FileManager.default
    do {
        try fileManager.createDirectory(at: moveToUrl, withIntermediateDirectories: true)

        try fileManager.moveItem(at: fileUrl, to: moveToUrl.appendingPathComponent(filename))

        try writeManifestToPath(manifestUrl: moveToUrl.appendingPathComponent("manifest.plist"),
                webUrl: "\(webUrl)\(filenameWithoutExt)/\(filename)", appName: appName, bundleId: bundleId, bundleVersion: bundleVersion)

        let htmlIndex = indexHtmlFile(manifestUrl: "\(webUrl)\(filenameWithoutExt)/manifest.plist", appName: appName, version: bundleVersion)
        try htmlIndex.write(to: moveToUrl.appendingPathComponent("index.html"),
                atomically: false,
                encoding: String.Encoding.utf8)

        appendLinkInHTML(htmlPath: htmlPath, linkToNewBuild: htmlIndex)

    } catch let error as NSError {
        print("Error: \(error.localizedDescription)")
    }
}

func getConfig(configPath: String, ipaPath: String, htmlPath: String) {
    let plistUrl = URL(fileURLWithPath: configPath)
    if let data = try? Data(contentsOf: plistUrl) {

        if let result = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] {

            if let bundleId = result["bundleId"] as? String,
               let bundleVersion = result["version"] as? String,
               let webUrl = result["webUrl"] as? String,
               let appName = result["appName"] as? String {

                moveToFolderAndCreateFiles(fileName: ipaPath,
                        webUrl: webUrl, appName: appName, bundleId: bundleId, bundleVersion: bundleVersion, htmlPath: htmlPath)
            } else {
                print("Error getting list from information, required: bundleId, version, webUrl, appName")
            }
        } else {
            print("Error reading config property list at: \(configPath)")
        }
    }
}

func validateData() {
    if CommandLine.arguments.count <= 1 {
        return print("To few args")
    }

    for index in 0..<CommandLine.arguments.count {
        let argument = CommandLine.arguments[index]

        if argument == "-config" {
            configFilePath = CommandLine.arguments[index + 1]
        }

        if argument == "-ipaPath" {
            ipaPath = CommandLine.arguments[index + 1]
        }

        if argument == "-htmlPath" {
            htmlPath = CommandLine.arguments[index + 1]
        }

        if argument == "-buildNumber" {
            buildNumber = CommandLine.arguments[index + 1]
        }
    }
    getConfig(configPath: configFilePath, ipaPath: ipaPath, htmlPath: htmlPath)
}

validateData()