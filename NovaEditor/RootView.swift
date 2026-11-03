//
//  RootView.swift
//  Nova Editor — raiz do app com TabView custom.
//

import SwiftUI

enum Tab: Int, CaseIterable { case inicio, projetos, presets, perfil }

struct RootView: View {
    @State private var tab: Tab = .inicio
    @State private var editingProject: Project? = nil

    var body: some View {
        ZStack {
            NovaTheme.bg.ignoresSafeArea()

            Group {
                if let p = editingProject {
                    EditorView(project: p, onClose: { editingProject = nil })
                } else {
                    switch tab {
                    case .inicio:   HomeView(onOpenProject: { editingProject = $0 },
                                             onGoProjects: { tab = .projetos })
                    case .projetos: ProjectsView(onOpen: { editingProject = $0 })
                    case .presets:  PlaceholderView(title: "Presets")
                    case .perfil:   PlaceholderView(title: "Perfil")
                    }
                }
            }

            if editingProject == nil {
                VStack { Spacer(); NovaTabBar(tab: $tab) }
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 42))
                .foregroundColor(NovaTheme.sec)
            Text(title).font(.title3.bold()).foregroundColor(.white)
            Text("Aba do app original — layout fiel chega quando houver screenshot dela.")
                .font(.caption).foregroundColor(NovaTheme.sec)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NovaTheme.bg)
    }
}

#Preview { RootView() }
