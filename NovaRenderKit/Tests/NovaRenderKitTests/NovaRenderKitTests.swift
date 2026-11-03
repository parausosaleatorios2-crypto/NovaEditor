import XCTest
@testable import NovaRenderKit
import NovaProjectKit

final class NovaRenderKitTests: XCTestCase {

    func testRendererBoots() throws {
        // Skip no simulador que não tem Metal
        guard MTLCreateSystemDefaultDevice() != nil else {
            throw XCTSkip("No Metal device")
        }
        let r = try Renderer()
        XCTAssertNotNil(r.queue)
        XCTAssertNotNil(r.library)
    }

    func testEffectRegistryResolves() throws {
        let eff = NovaEffect(type: "nova.effect.blur", name: "Blur")
        let m = EffectRegistry.shared.resolve(eff)
        XCTAssertNotNil(m)
    }

    func testEffectCatalogImplementedCount() {
        // Pelo menos 25 efeitos cobertos pela engine
        XCTAssertGreaterThanOrEqual(EffectCatalog.implementedCount(), 25)
    }

    func testTransformIdentityMatches() {
        let layer = NovaLayer(name: "L", type: .solid)
        let m = TransformMath.modelMatrix(layer: layer,
                                          layerSize: .init(100, 100),
                                          compSize: .init(1080, 1920),
                                          time: 0)
        // Matrix não é zero
        XCTAssertFalse(m.columns.0.x == 0 && m.columns.1.y == 0)
    }
}
