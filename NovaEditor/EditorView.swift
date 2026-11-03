//
//  EditorView.swift
//  Tela 3+4+5 — Editor com viewport, transport, timeline, bottom bar,
//  overlay de camada selecionada (grid de ferramentas), sheet Efeitos.
//

import SwiftUI
import NovaProjectKit
import NovaRenderKit

enum EditorPanel { case none, layerTools, effectsSheet, effectBrowser, effectSearch }

struct EditorView: View {
    let project: Project
    let onClose: () -> Void

    @State private var panel: EditorPanel = .none
    @State private var layerSelected: Bool = false
    @State private var timeText = "00:00:40"
    @State private var playing = false
    @State private var time: Double = 0

    // Projeto demo pra alimentar o render — enquanto o load real do .nova
    // não plugar nos projetos do usuário.
    @State private var demoProject: NovaProject = DemoProject.build()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                topBar
                viewport
                transport
                timeline
                bottomArea
            }
            .background(NovaTheme.bg)

            if panel == .effectsSheet { effectsSheet.transition(.move(edge: .bottom)) }
        }
        .fullScreenCover(isPresented: Binding(
            get: { panel == .effectBrowser || panel == .effectSearch },
            set: { if !$0 { panel = .effectsSheet } }
        )) {
            if panel == .effectSearch {
                EffectSearchView(onBack: { panel = .effectBrowser })
            } else {
                EffectBrowserView(onBack: { panel = .effectsSheet },
                                  onSearch: { panel = .effectSearch })
            }
        }
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack(spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "arrow.left").font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
            HStack(spacing: 6) {
                Text(layerSelected ? "Vídeo" : project.name)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                if layerSelected {
                    Image(systemName: "pencil").font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
                }
            }
            Spacer()
            if layerSelected {
                topBtn(system: "square.on.square.dashed") {}
                topBtn(system: "trash", color: NovaTheme.red) {}
            }
            topBtn(system: "diamond.fill", color: NovaTheme.diamond) {}
            Button(action: {}) {
                ZStack {
                    Circle().fill(Color(hex:"1B3A3A")).frame(width: 34, height: 34)
                    Text("⋮").foregroundColor(.white).font(.system(size: 18, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
    }

    private func topBtn(system: String, color: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system).font(.system(size: 17)).foregroundColor(color)
                .frame(width: 34, height: 34)
        }
    }

    // MARK: Viewport
    private var viewport: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle().fill(NovaTheme.bg)
            // canvas 4:5 — agora puxa do NovaRenderKit (Metal)
            HStack {
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    NovaPlayerView(project: demoProject, compIndex: 0,
                                   time: $time, playing: playing)
                        .aspectRatio(4.0/5.0, contentMode: .fit)
                        .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .frame(maxHeight: 220)
                    Text("¼").font(.system(size: 10)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(3)
                        .padding(6)
                }
                if layerSelected {
                    zoomSlider.padding(.leading, 4)
                }
                Spacer()
            }
            .padding(.vertical, 14)
        }
        .frame(height: 240)
    }

    private var zoomSlider: some View {
        VStack {
            Circle().fill(.white).frame(width: 10, height: 10)
            Rectangle().fill(NovaTheme.accent).frame(width: 2)
            Rectangle().fill(.white).frame(width: 10, height: 10)
        }
        .frame(width: 20, height: 200)
    }

    // MARK: Transport
    private var transport: some View {
        HStack(spacing: 2) {
            Spacer()
            tBtn("arrow.uturn.backward")
            tBtn("arrow.uturn.forward")
            tBtn("backward.end.fill")
            Button(action: { playing.toggle() }) {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 20)).foregroundColor(.white)
                    .frame(width: 44, height: 36)
            }
            tBtn("forward.end.fill")
            tBtn("plus.square.on.square")
            tBtn("arrow.up.left.and.arrow.down.right")
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func tBtn(_ system: String) -> some View {
        Button(action: {}) {
            Image(systemName: system).font(.system(size: 17)).foregroundColor(.white)
                .frame(width: 36, height: 32)
        }
    }

    // MARK: Timeline
    private var timeline: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    Text("‹").foregroundColor(NovaTheme.sec).font(.system(size: 14)).frame(width: 14)
                    Rectangle().fill(
                        LinearGradient(stops: [.init(color: NovaTheme.sec.opacity(0.6), location: 0),
                                               .init(color: NovaTheme.sec.opacity(0.6), location: 0.02),
                                               .init(color: .clear, location: 0.02)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 2)
                    .padding(.leading, 80)
                    .mask(
                        LinearGradient(gradient: Gradient(stops: (0...50).map { i in
                            .init(color: i % 2 == 0 ? .white : .clear, location: Double(i)/50)
                        }), startPoint: .leading, endPoint: .trailing)
                    )
                    Spacer()
                }
                .frame(height: 16)
                Text(timeText).font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .background(NovaTheme.bg)
                    .offset(x: 170, y: -2)
            }
            trackRow(eye: true, typ: "square.fill", bg: Color(hex:"1A2A30"), segment: true)
            trackRow(eye: true, typ: "square.fill", bg: Color(hex:"1A2A30"), segment: true)
            trackRow(eye: true, typ: "gear",        bg: Color(hex:"5A3A7A"), clip: .adjust)
            trackRow(eye: true, typ: "square.fill", bg: Color(hex:"1A2A30"), clip: .video, highlighted: layerSelected)
            if !layerSelected {
                trackRow(eye: true, typ: "square.fill", bg: Color(hex:"1A2A30"), clip: .video2)
            }
        }
        .padding(.top, 4)
        .overlay(alignment: .top) {
            // playhead
            Rectangle().fill(NovaTheme.red).frame(width: 2)
                .offset(x: -40)
                .overlay(alignment: .top) {
                    Circle().fill(NovaTheme.red).frame(width: 10, height: 10).offset(x: -40, y: -4)
                }
        }
    }

    enum ClipKind { case none, adjust, video, video2 }

    private func trackRow(eye: Bool, typ: String, bg: Color,
                          clip: ClipKind = .none, segment: Bool = false,
                          highlighted: Bool = false) -> some View {
        HStack(spacing: 4) {
            Circle().fill(NovaTheme.greenEye).frame(width: 8, height: 8).padding(.leading, 14)
            Circle().stroke(Color(hex:"666"), lineWidth: 1.5).frame(width: 14, height: 14)
            RoundedRectangle(cornerRadius: 3).fill(bg).frame(width: 22, height: 22)
                .overlay(Image(systemName: typ).font(.system(size: 10)).foregroundColor(.white))
            ZStack(alignment: .leading) {
                Color.clear
                if segment {
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex:"5A7A8A"))
                        .frame(width: 10, height: 12)
                        .offset(x: 80)
                }
                if clip == .adjust {
                    clipBox(color: Color(hex:"5A3A4A"), border: Color(hex:"7A4A5A"),
                            text: "◆ Adjustme...", wave: true, highlighted: false, width: 60).offset(x: 60)
                }
                if clip == .video {
                    clipBox(color: Color(hex:"2A4A4A"), border: highlighted ? .white : Color(hex:"3A6A6A"),
                            text: "Vídeo", wave: false, highlighted: highlighted, width: 120).offset(x: 60)
                }
                if clip == .video2 {
                    clipBox(color: Color(hex:"1A3A3A"), border: Color(hex:"2A5A5A"),
                            text: "Vídeo", wave: false, highlighted: false, width: 120).offset(x: 60)
                }
            }
            .frame(height: 24)
            .padding(.trailing, 10)
        }
        .frame(height: 30)
    }

    private func clipBox(color: Color, border: Color, text: String, wave: Bool,
                         highlighted: Bool, width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4).fill(color)
            RoundedRectangle(cornerRadius: 4).stroke(border, lineWidth: highlighted ? 1.5 : 1)
            if wave {
                HStack(spacing: 1) {
                    ForEach(0..<30) { i in
                        Rectangle().fill(Color.white.opacity(0.4))
                            .frame(width: 1, height: CGFloat.random(in: 2...18))
                    }
                }.padding(.horizontal, 8)
            }
            Text(text).font(.system(size: 10)).foregroundColor(.white)
                .padding(.horizontal, 6)
        }
        .frame(width: width, height: 20)
    }

    // MARK: Bottom area (bar OR toolgrid)
    @ViewBuilder
    private var bottomArea: some View {
        if layerSelected {
            layerToolGrid
        } else {
            bottomBar
        }
    }

    private var bottomBar: some View {
        HStack {
            Spacer()
            bItem(highlight: true, label: "Adicionar", icon: nil, custom: AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(NovaTheme.greenAdd).frame(width: 40, height: 40)
                    Image(systemName: "plus").font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                }
            )).onTapGesture { layerSelected = true }
            Spacer()
            bItem(label: "IA", icon: "sparkles")
            Spacer()
            bItem(label: "Biblioteca", icon: "icloud.and.arrow.down")
            Spacer()
            bItem(label: "Legendas", icon: "captions.bubble")
            Spacer()
            bItem(label: "Remover BG", icon: "wand.and.stars").onTapGesture { layerSelected = true }
            Spacer()
        }
        .frame(height: 70)
        .background(NovaTheme.bg)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(NovaTheme.border), alignment: .top)
    }

    private func bItem(highlight: Bool = false, label: String, icon: String?, custom: AnyView? = nil) -> some View {
        VStack(spacing: 4) {
            if let c = custom { c }
            else if let i = icon {
                Image(systemName: i).font(.system(size: 18))
                    .foregroundColor(highlight ? NovaTheme.greenAdd : .white)
            }
            Text(label).font(.system(size: 9.5))
                .foregroundColor(highlight ? NovaTheme.greenAdd : .white)
        }
    }

    // Grid de ferramentas de camada
    private var layerToolGrid: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(["speedometer", "arrow.left.to.line.compact", "scissors", "arrow.right.to.line.compact", "speaker.wave.2.fill"], id: \.self) { ic in
                        RoundedRectangle(cornerRadius: 9).fill(NovaTheme.card).frame(height: 46)
                            .overlay(Image(systemName: ic).foregroundColor(.white).font(.system(size: 18)))
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 4), spacing: 7) {
                    toolBtn(icon: "drop.fill", label: "Opacidade e\nmesclagem")
                    toolBtn(icon: "a.circle", label: "Animar")
                    toolBtn(icon: "scissors", label: "Recortar\nfundo")
                    toolBtn(icon: "mountain.2.fill", label: "Profundidade")
                    toolBtn(icon: "arrow.up.and.down.and.arrow.left.and.right", label: "Movimentação e\ntransformação")
                    toolBtn(icon: "square.dashed.inset.filled", label: "Rastrear\nmovimento")
                    toolBtn(icon: "circle.hexagongrid", label: "Ossos")
                    toolBtn(icon: "sparkles", label: "Efeitos", action: {
                        withAnimation { panel = .effectsSheet }
                    })
                }
            }
            .padding(10)
        }
        .frame(maxHeight: .infinity)
        .background(NovaTheme.bg)
    }

    private func toolBtn(icon: String, label: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(.white)
                Text(label).font(.system(size: 10)).foregroundColor(.white)
                    .multilineTextAlignment(.center).lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(NovaTheme.card)
            .cornerRadius(10)
        }
    }

    // MARK: Effects sheet
    private var effectsSheet: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { withAnimation { panel = .none } } label: {
                    Text("‹").foregroundColor(.white).font(.system(size: 20, weight: .semibold))
                }
                Text("Efeitos").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Spacer()
                Button(action: {}) {
                    Text("Presets").foregroundColor(.white).font(.system(size: 12))
                        .padding(.horizontal, 14).frame(height: 32)
                        .background(Capsule().stroke(Color(hex:"3A4A4E"), lineWidth: 1))
                }
                Button { panel = .effectBrowser } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text("Efeito").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).frame(height: 34)
                    .background(Capsule().fill(NovaTheme.greenAdd))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            VStack(spacing: 10) {
                Text("Os efeitos rodam em cadeia, de cima para baixo,\nsobre o que a camada desenhou.")
                    .font(.system(size: 13)).foregroundColor(NovaTheme.sec)
                    .multilineTextAlignment(.center)
                Text("Toque em “+ Efeito” para começar.")
                    .font(.system(size: 13)).foregroundColor(NovaTheme.sec)
            }
            .frame(maxWidth: .infinity).padding(40)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: 280)
        .background(Color(hex:"1A2A2E"))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .overlay(alignment: .bottomLeading) {
            Circle().fill(Color(hex:"1A3A40")).frame(width: 32, height: 32)
                .overlay(Text("⋯").foregroundColor(Color(hex:"8A9A9C")))
                .padding(14)
        }
    }
}

// Helper para rounded corners seletivos
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
