# Nova Editor — porte iOS (pacote final com engine Metal)

Projeto Xcode + 2 Swift Packages locais + 7 telas SwiftUI dos screenshots
+ **engine de render em Metal que roda os efeitos de verdade**.

## Estrutura

```
NovaEditor-iOS/
├── NovaEditor.xcodeproj/              projeto Xcode (iOS 15+, Swift 5)
├── NovaEditor/                        app SwiftUI
│   ├── NovaEditorApp.swift            @main
│   ├── RootView.swift                 TabBar + rotas
│   ├── NovaTabBar.swift               bottom nav
│   ├── NovaTheme.swift                paleta dos prints
│   ├── Project.swift                  modelo UI + 6 projetos
│   ├── DemoProject.swift              composição que alimenta o viewport
│   ├── HomeView.swift                 Tela 1 — Início
│   ├── ProjectsView.swift             Tela 2 — grid 2 colunas
│   ├── EditorView.swift               Telas 3+4+5 — com NovaPlayerView real
│   ├── EffectBrowserView.swift        Tela 6 — Navegador (18 cats)
│   ├── EffectSearchView.swift         Tela 7 — Busca Cor com badge ●
│   ├── Info.plist / LaunchScreen / Assets.xcassets
│
├── NovaProjectKit/                    pacote 1 — modelo .nova + IO
│   └── Sources/NovaProjectKit/        NovaProject, Document, Zip, AEImport, OFPFlare
│
└── NovaRenderKit/                     pacote 2 — ENGINE METAL
    ├── Package.swift
    └── Sources/NovaRenderKit/
        ├── Renderer.swift             MTLDevice + cache de pipelines
        ├── RenderTarget.swift         ping-pong de texturas
        ├── TextureCache.swift         carrega mídia/texto/forma → MTLTexture
        ├── Transforms.swift           modelMatrix da camada
        ├── Effect.swift               17 efeitos concretos em Swift
        ├── EffectRegistry.swift       resolve NovaEffect → MetalEffect
        ├── EffectCatalog.swift        tabela nome do app → id interno
        ├── LayerRenderer.swift        rasteriza camada + chain de efeitos
        ├── CompositionRenderer.swift  orquestra a composition inteira
        ├── PlayerView.swift           MTKView em SwiftUI
        ├── Exporter.swift             AVAssetWriter → .mp4
        └── Shaders/Shaders.metal      22 shaders (vertex + fragments)
```

## O que a engine FAZ de verdade (não é lista, é código rodando)

| Efeito                   | Shader           | Status |
|--------------------------|------------------|--------|
| Desfoque gaussiano       | fs_blur          | ✅     |
| Glow / Brilho interno    | fs_bright + blur + add | ✅ |
| Color grade (bright/contrast/sat/gamma/temp/tint/exposure) | fs_grade | ✅ |
| Apply Color LUT (3D)     | fs_lut           | ✅     |
| HSL / Matiz / Saturação  | fs_hsl           | ✅     |
| Levels                   | fs_levels        | ✅     |
| Chroma Key (keying)      | fs_chroma        | ✅     |
| Vinheta                  | fs_vignette      | ✅     |
| Grain (film)             | fs_grain         | ✅     |
| Aberração cromática      | fs_chrom         | ✅     |
| VHS                      | fs_vhs           | ✅     |
| Pixelate                 | fs_pixelate      | ✅     |
| Mirror X/Y               | fs_mirrorX/Y     | ✅     |
| Invert                   | fs_invert        | ✅     |
| Threshold                | fs_threshold     | ✅     |
| Sharpen (unsharp mask)   | fs_sharpen       | ✅     |
| Motion blur direcional   | fs_motion        | ✅     |
| Tilt-shift               | fs_tilt          | ✅     |
| Transform (anchor/pos/scale/rotation/opacity) | vs_xform + fs_xform | ✅ |
| 8 blend modes (over/mul/screen/overlay/lighten/darken/diff/add) | fs_blend | ✅ |

Keyframes com easing (linear/hold/easeIn/easeOut/easeInOut/bezier aprox)
são samplados a cada frame pelo `TransformMath` e aplicados no quad.

## O viewport do EditorView AGORA mostra render real

Abriu o editor → `NovaPlayerView` monta um `MTKView` que roda o
`DemoProject`: um solid roxo com **Glow aplicado em Metal**, movendo-se
em 4 keyframes de posição + rotação 0→360° + um texto "Nova Editor"
com fade in/out via keyframes de opacidade + camada de ajuste
"Vinheta" por cima da composition inteira.

Play/pause no transport controla o tempo. Scrubbing na timeline
também mexe no tempo (quando ligar o binding).

## Build

### No Mac, Xcode 15+
```bash
cd NovaEditor-iOS
open NovaEditor.xcodeproj
# Signing & Capabilities → Team
# Product → Archive → Distribute → Development → .ipa
```

### CI (sem Mac)
```bash
cd NovaProjectKit && swift test   # 5 testes do modelo
cd ../NovaRenderKit && swift test # 4 testes da engine (requer Metal)
xcodebuild -project NovaEditor.xcodeproj -scheme NovaEditor -configuration Release archive
```

### Importar .aepx do After Effects
```swift
let proj = try AEImport.importAEPX(from: aepxURL)
// → NovaProject com transform+keyframes extraídos
// → camadas e efeitos como stubs; efeitos cujo matchName
//   mapeia pra EffectRegistry viram shaders Metal rodando de verdade
```

## O que NÃO está aqui ainda

- Shaders dos ~290 efeitos restantes (dos 316 no catálogo original)
  — a arquitetura aceita cada novo como `MetalEffect` + um `fragment` no .metal
- Timeline totalmente editável (atualmente lê, não escreve ainda)
- Áudio mix (AVAudioEngine wired, mas sem shaders de áudio)
- Expressões do AE (loopOut, wiggle, …)
- 3D camera real (está como data path, falta projeção perspectiva)
- Backend novavisionhub-3.onrender.com

Essas peças plugam onde a arquitetura já tem o ponto de encaixe
(`Effect.swift` pra cada shader novo, `AVAudioMix` pro áudio, etc.).

## Audit — origem de cada peça do pacote

Igual aos readmes anteriores: nomes, cores, ícone, strings, categorias,
chaves de schema — tudo vem do APK + 8 screenshots.
O que é código novo: a implementação Metal dos 20+ efeitos — essa é
engine escrita do zero para rodar o que o original só tem como lib C++
Android (não portável). Zero conteúdo copiado de código do APK.
