# NovaProjectKit

Leitor/escritor Swift do formato de projeto do **Nova Editor** (`.nova`),
mais um importador mínimo de **After Effects** (`.aepx`) e um ponteiro de
flare para **Optical Flares** (`.ofp`).

Zero dependências externas, iOS 15+ / macOS 12+. Usa `Compression.framework`
para zip DEFLATE.

## Por que isto existe (opção B)

O editor do Nova Editor roda sobre uma engine nativa C++ (lib/arm64-v8a/)
que não é portável para iOS sem recompilação direcionada. **Antes** de
começar o porte da engine, este pacote resolve o problema que não espera:
**ler o `.nova` dos seus projetos existentes** no futuro app iOS, sem
depender da engine original.

## Fontes do schema

Todas as chaves JSON e nomes de classe deste pacote foram extraídos
direto do APK oficial `NovaEditor-0_894_0.apk` (classes.dex + classes2.dex),
dos pacotes:

- `com.novaeditor.persistence.*` — persistência do projeto
- `com.novaeditor.layout.*`       — modelo de composição/layout
- `com.novaeditor.model.*`        — primitivos
- `com.novaeditor.aeimport.*`     — AeComp, AeLayer, AeKey, AeProp, AeEase, AeCurva, AeLook, AeLut, AeParam

As 59 chaves de schema identificadas no DEX e usadas aqui:
`anchor, assets, audio, backgroundColor, blend, blendMode, camera,
children, color, composition, curve, duration, easing, effect, effects,
end, file, fps, frameRate, guides, height, hidden, keyframes, layer,
layers, locked, marker, markers, mask, media, mode, name, null, opacity,
out, parent, parentId, path, pin, position, preset, project, rotation,
scale, shape, solid, speed, start, template, text, time, timeline,
transform, trim, type, value, velocity, version, width`.

## Formato do pacote `.nova`

```
projeto.nova  (ZIP; MIME application/x-nova — do manifest do APK)
├── project.json           NovaProject em JSON (UTF-8)
└── media/
    ├── <uuid>.mp4
    ├── <uuid>.png
    ├── <uuid>.ttf
    └── ...
```

## Uso

```swift
import NovaProjectKit

// Abrir um .nova
let doc = try NovaDocument.load(from: url)
print(doc.project.name)
for comp in doc.project.compositions {
    for layer in comp.layers {
        print(layer.name, layer.type)
    }
}

// Importar um .aepx (XML do After Effects)
let aeProject = try AEImport.importAEPX(from: aepxURL)

// Salvar um .nova
try NovaDocument(project: aeProject).save(to: destURL)
```

## Plugar no projeto Xcode do shell iOS

No `NovaEditor-iOS` que te entreguei:

1. Copie a pasta `NovaProjectKit/` ao lado do `.xcodeproj`.
2. Em Xcode → File → Add Package Dependencies → **Add Local...**  → aponte pra `NovaProjectKit`.
3. Em Signing & Capabilities do target `NovaEditor`, Frameworks → adicione `NovaProjectKit`.
4. No `ContentView.swift` já pode `import NovaProjectKit`.

## Status

- [x] Modelo `NovaProject` com todas as chaves do DEX
- [x] Reader/Writer `.nova` (ZIP + project.json)
- [x] Writer com DEFLATE via Compression.framework
- [x] Importador `.aepx` cobrindo transform (anchor/position/scale/rotation/opacity) com keyframes e easing
- [x] Hooks para `.ofp` (Optical Flares)
- [x] Testes: roundtrip JSON, ZIP, interpolação linear, AE import, OFP
- [ ] Suporte a `.aep` binário (requer Bento MOV reader; fora deste escopo)
- [ ] Resolução de assets referenciados por `AeImport` (depende do bundle AE que o usuário trouxer)

## Licença

MIT.
