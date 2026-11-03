//
//  AEImport.swift
//
//  Importador de projetos do After Effects (.aepx — AE Project XML)
//  para o modelo NovaProject.
//
//  Por que .aepx e não .aep: o .aep é um binário proprietário da Adobe
//  (Bento MOV atom-tree) que exige RIFEX/XMP reader interno; o .aepx é
//  o mesmo projeto exportado em XML plano por "File → Save As → Adobe
//  After Effects XML Project (.aepx)" e é lido com XMLParser.
//
//  O apk expõe as classes abaixo em com.novaeditor.aeimport.*:
//    AeComp, AeLayer, AeKey, AeProp, AeEase, AeCurva, AeLook, AeLut,
//    AeParam.
//
//  Esta implementação faz UM pipeline mínimo: pega composições,
//  camadas, propriedades de transform (anchor/position/scale/rotation/
//  opacity) e seus keyframes, com easing. Efeitos vêm como stubs
//  com nome, prontos pra serem resolvidos por um registry externo.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

public enum AEImportError: Error { case invalidXML, missingRoot(String) }

public final class AEImport: NSObject, XMLParserDelegate {

    public static func importAEPX(from url: URL) throws -> NovaProject {
        let d = try Data(contentsOf: url)
        return try importAEPX(data: d, projectName: url.deletingPathExtension().lastPathComponent)
    }

    public static func importAEPX(data: Data, projectName: String) throws -> NovaProject {
        let p = AEImport(projectName: projectName)
        let parser = XMLParser(data: data)
        parser.delegate = p
        if !parser.parse() { throw AEImportError.invalidXML }
        return p.build()
    }

    // MARK: - Internals

    private let projectName: String
    private var comps: [AeComp] = []
    private var currentComp: AeComp?
    private var currentLayer: AeLayer?
    private var currentProp: AeProp?
    private var elementStack: [String] = []
    private var attributesStack: [[String: String]] = []
    private var text: String = ""

    init(projectName: String) { self.projectName = projectName }

    // Elementos esperados num .aepx:
    //   <Project> <Comp>...<Comp/> <Layer>... <Prop name="Position">
    //      <Keyframe time="..." value="..." interpolation="..."/>
    //   </Prop></Layer></Project>
    //
    // O schema real do .aepx é vasto; cobrimos o subconjunto que
    // o Nova Editor efetivamente consome (as classes Ae* no apk
    // sugerem exatamente este subset).

    public func parser(_ parser: XMLParser, didStartElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?,
                       attributes attributeDict: [String : String] = [:]) {
        elementStack.append(elementName)
        attributesStack.append(attributeDict)
        text = ""
        switch elementName {
        case "Comp", "Composition":
            currentComp = AeComp(
                name: attributeDict["name"] ?? "Comp",
                width: Int(attributeDict["width"] ?? "1920") ?? 1920,
                height: Int(attributeDict["height"] ?? "1080") ?? 1080,
                frameRate: Double(attributeDict["frameRate"] ?? "30") ?? 30,
                duration: Double(attributeDict["duration"] ?? "10") ?? 10
            )
        case "Layer":
            currentLayer = AeLayer(
                name: attributeDict["name"] ?? "Layer",
                aeType: attributeDict["type"] ?? "av",
                start: Double(attributeDict["startTime"] ?? "0") ?? 0,
                end:   Double(attributeDict["outPoint"]  ?? "5") ?? 5
            )
        case "Prop", "Property":
            currentProp = AeProp(name: attributeDict["name"] ?? "")
        case "Keyframe":
            if var p = currentProp {
                let t = Double(attributeDict["time"] ?? "0") ?? 0
                let v = attributeDict["value"] ?? ""
                let interp = attributeDict["interpolation"] ?? "linear"
                p.keyframes.append(AeKey(time: t, rawValue: v, interp: interp))
                currentProp = p
            }
        case "Effect":
            if var l = currentLayer {
                l.effects.append(AeEffectRef(name: attributeDict["name"] ?? "Effect",
                                             matchName: attributeDict["matchName"]))
                currentLayer = l
            }
        default: break
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }

    public func parser(_ parser: XMLParser, didEndElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "Prop", "Property":
            if var l = currentLayer, let p = currentProp {
                l.props[p.name.lowercased()] = p
                currentLayer = l
            }
            currentProp = nil
        case "Layer":
            if var c = currentComp, let l = currentLayer {
                c.layers.append(l); currentComp = c
            }
            currentLayer = nil
        case "Comp", "Composition":
            if let c = currentComp { comps.append(c) }
            currentComp = nil
        default: break
        }
        _ = elementStack.popLast(); _ = attributesStack.popLast()
    }

    // Build NovaProject
    func build() -> NovaProject {
        var out = NovaProject(name: projectName, compositions: [], assets: [])
        for c in comps {
            var comp = NovaComposition(name: c.name, width: c.width, height: c.height,
                                       frameRate: c.frameRate, duration: c.duration)
            for l in c.layers {
                var layer = NovaLayer(name: l.name,
                                      type: AEImport.mapType(l.aeType),
                                      start: l.start, end: l.end)
                layer.transform = AEImport.buildTransform(from: l.props)
                if let opacity = l.props["opacity"] {
                    layer.opacity = AEImport.makeDoubleProperty(opacity, defaultValue: 1.0, scale: 1.0/100.0)
                }
                for eff in l.effects {
                    layer.effects.append(NovaEffect(type: eff.matchName ?? eff.name, name: eff.name))
                }
                comp.layers.append(layer)
            }
            out.compositions.append(comp)
        }
        return out
    }

    static func mapType(_ ae: String) -> NovaLayerType {
        switch ae.lowercased() {
        case "null":        return .null
        case "text":        return .text
        case "shape":       return .shape
        case "camera":      return .camera
        case "light":       return .light
        case "solid":       return .solid
        case "adjustment":  return .adjustment
        case "audio":       return .audio
        case "precomp":     return .precomp
        default:            return .media
        }
    }

    static func buildTransform(from props: [String: AeProp]) -> NovaTransform {
        return NovaTransform(
            anchor:   makeVec2Property(props["anchor point"] ?? props["anchor"], defaultValue: .zero),
            position: makeVec2Property(props["position"], defaultValue: .zero),
            scale:    makeVec2Property(props["scale"],    defaultValue: .one),
            rotation: makeDoubleProperty(props["rotation"], defaultValue: 0, scale: 1.0)
        )
    }

    static func makeDoubleProperty(_ prop: AeProp?, defaultValue: Double, scale: Double) -> NovaProperty<Double> {
        guard let prop = prop else { return .constant(defaultValue) }
        if prop.keyframes.isEmpty {
            return .constant(Double(prop.name) ?? defaultValue)
        }
        let kfs = prop.keyframes.map { k -> NovaKeyframe<Double> in
            let v = (Double(k.rawValue) ?? defaultValue) * scale
            return NovaKeyframe(time: k.time, value: v, easing: mapEasing(k.interp))
        }
        return .keyframes(kfs)
    }

    static func makeVec2Property(_ prop: AeProp?, defaultValue: NovaVec2) -> NovaProperty<NovaVec2> {
        guard let prop = prop else { return .constant(defaultValue) }
        if prop.keyframes.isEmpty { return .constant(defaultValue) }
        let kfs = prop.keyframes.map { k -> NovaKeyframe<NovaVec2> in
            let xy = k.rawValue.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
            let v = NovaVec2(x: xy.first ?? 0, y: xy.dropFirst().first ?? 0)
            return NovaKeyframe(time: k.time, value: v, easing: mapEasing(k.interp))
        }
        return .keyframes(kfs)
    }

    static func mapEasing(_ s: String) -> NovaEasing {
        switch s.lowercased() {
        case "hold":    return .hold
        case "linear":  return .linear
        case "bezier":  return .bezier
        case "easein":  return .easeIn
        case "easeout": return .easeOut
        case "easeinout": return .easeInOut
        default:        return .linear
        }
    }
}

// MARK: - internal AE intermediates (nome das classes espelha com.novaeditor.aeimport.*)

struct AeComp {
    var name: String
    var width: Int
    var height: Int
    var frameRate: Double
    var duration: Double
    var layers: [AeLayer] = []
}
struct AeLayer {
    var name: String
    var aeType: String
    var start: Double
    var end: Double
    var props: [String: AeProp] = [:]
    var effects: [AeEffectRef] = []
}
struct AeProp {
    var name: String
    var keyframes: [AeKey] = []
}
struct AeKey {
    var time: Double
    var rawValue: String
    var interp: String
}
struct AeEffectRef {
    var name: String
    var matchName: String?
}
