import XCTest
@testable import NovaProjectKit

final class NovaProjectKitTests: XCTestCase {

    func testRoundtripJSONPreservesSchema() throws {
        let proj = NovaProject(
            name: "teste",
            compositions: [
                NovaComposition(
                    name: "Comp 1",
                    width: 1080, height: 1920,
                    frameRate: 30, duration: 10,
                    layers: [
                        NovaLayer(name: "Novo nulo", type: .null,
                                  start: 0, end: 10,
                                  transform: NovaTransform(
                                    anchor:   .constant(.zero),
                                    position: .keyframes([
                                        .init(time: 0,  value: .zero, easing: .easeIn),
                                        .init(time: 2,  value: .one,  easing: .easeOut)
                                    ]),
                                    scale:    .constant(.one),
                                    rotation: .constant(45))),
                        NovaLayer(name: "Camada de texto", type: .text,
                                  text: NovaTextContent(text: "Nova", fontName: "Inter", fontSize: 96, color: .white))
                    ])
            ])
        let doc = NovaDocument(project: proj)
        let data = try doc.data(pretty: true)
        let back = try NovaDocument.load(from: data)
        XCTAssertEqual(back.project, proj)
    }

    func testZipContainsProjectJSON() throws {
        let proj = NovaProject(name: "zipcheck", compositions: [NovaComposition(name: "c")])
        let doc  = NovaDocument(project: proj, mediaFiles: ["media/foo.txt": "hello".data(using: .utf8)!])
        let bytes = try doc.data()
        let entries = try NovaZip.read(bytes)
        XCTAssertNotNil(entries["project.json"])
        XCTAssertEqual(entries["media/foo.txt"], "hello".data(using: .utf8))
    }

    func testPropertySamplingLinear() {
        let p: NovaProperty<Double> = .keyframes([
            .init(time: 0, value: 0, easing: .linear),
            .init(time: 1, value: 100, easing: .linear)
        ])
        XCTAssertEqual(p.sample(at: 0),    0,   accuracy: 1e-9)
        XCTAssertEqual(p.sample(at: 0.5),  50,  accuracy: 1e-9)
        XCTAssertEqual(p.sample(at: 1),    100, accuracy: 1e-9)
        XCTAssertEqual(p.sample(at: 2),    100, accuracy: 1e-9) // clamp
    }

    func testAEImportMinimalXML() throws {
        let aepx = """
        <Project>
          <Comp name="Main" width="1080" height="1920" frameRate="30" duration="5">
            <Layer name="Nulo 1" type="null" startTime="0" outPoint="5">
              <Prop name="Position">
                <Keyframe time="0" value="100, 100" interpolation="linear"/>
                <Keyframe time="2" value="500, 800" interpolation="easeInOut"/>
              </Prop>
              <Prop name="Opacity">
                <Keyframe time="0" value="0"   interpolation="linear"/>
                <Keyframe time="1" value="100" interpolation="linear"/>
              </Prop>
            </Layer>
          </Comp>
        </Project>
        """.data(using: .utf8)!
        let proj = try AEImport.importAEPX(data: aepx, projectName: "ae")
        XCTAssertEqual(proj.compositions.count, 1)
        let comp = proj.compositions[0]
        XCTAssertEqual(comp.width, 1080)
        XCTAssertEqual(comp.height, 1920)
        XCTAssertEqual(comp.layers.count, 1)
        XCTAssertEqual(comp.layers[0].type, .null)
    }

    func testOFPFlareBecomesEffect() {
        let flare = OFPFlareRef(path: "opticalflares/padrao.ofp", name: "Padrão")
        let eff = flare.asEffect()
        XCTAssertEqual(eff.type, "nova.effect.opticalflares")
        XCTAssertEqual(eff.preset, "opticalflares/padrao.ofp")
    }
}
