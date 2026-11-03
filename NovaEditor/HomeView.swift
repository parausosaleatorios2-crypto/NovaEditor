//
//  HomeView.swift
//  Tela 1 — Início. Hero "Transforme suas ideias em realidade.",
//  cards Lab de IA + Projetos, Seus projetos horizontal, Ferramentas de IA.
//

import SwiftUI

struct HomeView: View {
    let onOpenProject: (Project) -> Void
    let onGoProjects: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            appbar
            ScrollView {
                VStack(spacing: 14) {
                    hero
                    HStack(spacing: 10) {
                        BigCard(title: "Lab de IA",
                                subtitle: "Ferramentas avançadas para elevar suas edições.",
                                bg: NovaTheme.labIA,
                                icon: "flask.fill",
                                iconColor: Color(hex:"C6B0FF"))
                        BigCard(title: "Projetos",
                                subtitle: "Acesse, organize e continue editando.",
                                bg: NovaTheme.card,
                                icon: "folder",
                                iconColor: NovaTheme.sec)
                            .onTapGesture { onGoProjects() }
                    }
                    .padding(.horizontal, NovaTheme.gutter)

                    sectionProjetos
                    sectionIA

                    Color.clear.frame(height: 80)
                }
                .padding(.top, 4)
            }
        }
        .background(NovaTheme.bg)
    }

    private var appbar: some View {
        HStack(spacing: 10) {
            Image("AppIconLogo").resizable().frame(width: 26, height: 26).cornerRadius(6)
            Text("Nova Editor").font(.system(size: 16, weight: .bold))
            Spacer()
            Circle().fill(Color(hex:"2FADDF")).frame(width: 30, height: 30)
                .overlay(Text("D").font(.system(size: 13, weight: .bold)).foregroundColor(.white))
        }
        .padding(.horizontal, NovaTheme.gutter)
        .padding(.vertical, 12)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex:"2A1A4A"), Color(hex:"4B2370"), Color(hex:"6D2A90")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Text("NAVISION")
                .font(.system(size: 60, weight: .black)).kerning(-1.5)
                .foregroundColor(.white.opacity(0.08))
                .offset(y: -8)
            VStack(alignment: .leading, spacing: 6) {
                Text("Transforme suas ideias em realidade.")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Edição profissional no seu bolso.")
                    .font(.system(size: 12)).foregroundColor(Color(hex:"D7CFFF"))
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 13, weight: .heavy))
                        Text("Nova composição").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).frame(height: 38)
                    .background(
                        Capsule().fill(LinearGradient(colors: [NovaTheme.accent, NovaTheme.accent2],
                                                     startPoint: .leading, endPoint: .trailing))
                    )
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: NovaTheme.cornerBig))
        .padding(.horizontal, NovaTheme.gutter)
    }

    private var sectionProjetos: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Seus projetos").font(.system(size: 17, weight: .heavy))
                Spacer()
                Button(action: onGoProjects) {
                    HStack(spacing: 3) { Text("Ver todos"); Image(systemName: "chevron.right") }
                        .font(.system(size: 12)).foregroundColor(NovaTheme.sec)
                }
            }
            .padding(.horizontal, NovaTheme.gutter)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SampleProjects.all.prefix(3)) { p in
                        ProjectCard(project: p, height: 120)
                            .frame(width: 160)
                            .onTapGesture { onOpenProject(p) }
                    }
                }
                .padding(.horizontal, NovaTheme.gutter)
            }
        }
    }

    private var sectionIA: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ferramentas de IA").font(.system(size: 17, weight: .heavy))
                Spacer()
                HStack(spacing: 3) { Text("Ver todas"); Image(systemName: "chevron.right") }
                    .font(.system(size: 12)).foregroundColor(NovaTheme.sec)
            }
            .padding(.horizontal, NovaTheme.gutter)
            HStack(spacing: 10) {
                ToolCard(title: "Recortar fundo", subtitle: "Isola o sujeito e devolve com transp…",
                         icon: "scissors")
                ToolCard(title: "Aumentar resol…", subtitle: "Quadruplica o tamanho sem virar …",
                         icon: "square.grid.2x2")
            }
            .padding(.horizontal, NovaTheme.gutter)
        }
    }
}

// MARK: - Blocos reutilizáveis

struct BigCard: View {
    let title: String
    let subtitle: String
    let bg: Color
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.08))
                .cornerRadius(7)
                .padding(.bottom, 12)
            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            Text(subtitle).font(.system(size: 10.5)).foregroundColor(NovaTheme.sec)
                .lineLimit(2)
                .padding(.top, 3)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(bg)
        .cornerRadius(12)
        .overlay(alignment: .trailing) {
            Image(systemName: "chevron.right")
                .foregroundColor(NovaTheme.mut).padding(.trailing, 12)
        }
    }
}

struct ToolCard: View {
    let title: String
    let subtitle: String
    let icon: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(NovaTheme.accent2)
                .frame(width: 34, height: 34)
                .background(NovaTheme.accent.opacity(0.14))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 10)).foregroundColor(NovaTheme.sec).lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(NovaTheme.card).cornerRadius(10)
    }
}

struct ProjectCard: View {
    let project: Project
    let height: CGFloat
    var showMenu: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                project.thumbColor.frame(height: height)
                Text(project.duration)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(4)
                    .padding(7)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name).font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white).lineLimit(1)
                Text("\(project.aspect) · \(project.resolution) · \(project.fps) · \(project.size)")
                    .font(.system(size: 10)).foregroundColor(NovaTheme.sec).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .overlay(alignment: .topTrailing) {
                if showMenu {
                    Text("⋮").foregroundColor(NovaTheme.sec).padding(.horizontal, 8).padding(.vertical, 4)
                }
            }
        }
        .background(NovaTheme.card)
        .cornerRadius(10)
    }
}
