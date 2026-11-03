//
//  NovaDocument.swift
//
//  Alto nível: abre e salva um arquivo .nova.
//
//  Formato do pacote (inferido dos sinais do APK — `application/x-nova`,
//  também declarado como `application/x-zip-compressed`, e das classes
//  com.novaeditor.persistence.*):
//
//      projeto.nova  (ZIP STORE/DEFLATE)
//      ├── project.json         (UTF-8, schema NovaProject)
//      └── media/
//          ├── <uuid>.mp4
//          ├── <uuid>.png
//          └── ...
//
//  O JSON é o único "índice" obrigatório. Mídias referenciadas por
//  `NovaMediaRef.file` ou `NovaAudioRef.file` ficam na pasta `media/`.
//
//  O reader é tolerante: aceita tanto um .nova zipado quanto um
//  project.json cru (durante dev / testes), e inclui um writer que
//  gera um .nova válido com a mídia embutida.
//

import Foundation

public enum NovaDocumentError: Error, Equatable {
    case notAZip
    case missingProjectJSON
    case invalidProjectJSON(String)
    case missingMedia(String)
    case ioError(String)
}

public struct NovaDocument {

    public let project: NovaProject
    public let mediaFiles: [String: Data]   // key = NovaAsset.file, value = conteúdo

    public init(project: NovaProject, mediaFiles: [String: Data] = [:]) {
        self.project = project
        self.mediaFiles = mediaFiles
    }

    // MARK: Load

    /// Carrega de uma URL — detecta automaticamente se é zip (.nova) ou json puro.
    public static func load(from url: URL) throws -> NovaDocument {
        let data = try Data(contentsOf: url)
        return try load(from: data)
    }

    public static func load(from data: Data) throws -> NovaDocument {
        if data.starts(with: [0x50, 0x4B, 0x03, 0x04]) || data.starts(with: [0x50, 0x4B, 0x05, 0x06]) {
            // zip
            let entries = try NovaZip.read(data)
            guard let json = entries["project.json"] else {
                throw NovaDocumentError.missingProjectJSON
            }
            let project = try decodeProject(json)
            var media: [String: Data] = [:]
            for (k, v) in entries where k.hasPrefix("media/") {
                media[k] = v
            }
            return NovaDocument(project: project, mediaFiles: media)
        } else {
            // plain json
            let project = try decodeProject(data)
            return NovaDocument(project: project)
        }
    }

    public static func decodeProject(_ data: Data) throws -> NovaProject {
        do {
            let dec = JSONDecoder()
            return try dec.decode(NovaProject.self, from: data)
        } catch {
            throw NovaDocumentError.invalidProjectJSON("\(error)")
        }
    }

    // MARK: Save

    public func data(pretty: Bool = false) throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = pretty ? [.prettyPrinted, .sortedKeys] : []
        let json = try enc.encode(project)

        var entries: [(String, Data)] = [("project.json", json)]
        for (k, v) in mediaFiles.sorted(by: { $0.key < $1.key }) {
            entries.append((k, v))
        }
        return NovaZip.write(entries)
    }

    public func save(to url: URL, pretty: Bool = false) throws {
        try data(pretty: pretty).write(to: url, options: .atomic)
    }
}
