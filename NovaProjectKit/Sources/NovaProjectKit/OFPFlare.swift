//
//  OFPFlare.swift
//
//  Leitor de arquivos .ofp — formato de FLARE do plugin Optical Flares
//  (Video Copilot). No APK do Nova Editor isso aparece como:
//
//    "um flare do Optical Flares (.ofp)"
//    "opticalflares/padrao.ofp"
//    "Abrir .ofp"
//
//  O arquivo .ofp é um binário próprio (não é projeto). Este módulo
//  deixa a porta aberta para alimentar o motor Optical Flares embutido
//  no futuro app iOS, mas por ora só expõe:
//    - a lista de arquivos .ofp embutidos no bundle do app, e
//    - uma struct de referência que pode ser aplicada a um NovaEffect.
//

import Foundation

public struct OFPFlareRef: Codable, Equatable {
    /// Nome relativo dentro do bundle: ex. "opticalflares/padrao.ofp"
    public var path: String
    /// Rótulo exibido na UI (nome do flare).
    public var name: String
    public init(path: String, name: String) { self.path = path; self.name = name }

    /// Converte a referência num NovaEffect pronto pra ir numa camada.
    public func asEffect() -> NovaEffect {
        return NovaEffect(
            type: "nova.effect.opticalflares",
            name: "Optical Flares",
            preset: path,
            parameters: ["flare": .string(name)]
        )
    }
}
