//
//  ProjectsView.swift
//  Tela 2 — Grid 2 colunas de projetos, chip "Tudo", "Novo projeto".
//

import SwiftUI

struct ProjectsView: View {
    let onOpen: (Project) -> Void
    @State private var gridMode = true

    var body: some View {
        VStack(spacing: 0) {
            appbar
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    filters
                    grid
                    Color.clear.frame(height: 80)
                }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Seus projetos").font(.system(size: 28, weight: .heavy))
            Text("Organize, edite e continue criando.")
                .font(.system(size: 12)).foregroundColor(NovaTheme.sec)
            HStack(spacing: 10) {
                Text("Tudo").font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).frame(height: 34)
                    .background(Capsule().fill(NovaTheme.accent))
                Circle().fill(NovaTheme.card).frame(width: 34, height: 34)
                    .overlay(Image(systemName: "plus").foregroundColor(.white).font(.system(size: 12, weight: .bold)))
                Spacer()
                Image(systemName: "clock.arrow.circlepath").foregroundColor(NovaTheme.sec).font(.system(size: 16))
                Image(systemName: "doc.badge.arrow.up").foregroundColor(NovaTheme.sec).font(.system(size: 16))
                Button(action: {}) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text("Novo projeto").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).frame(height: 34)
                    .background(Capsule().fill(NovaTheme.accent))
                }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, NovaTheme.gutter)
    }

    private var filters: some View {
        HStack {
            HStack(spacing: 5) {
                Text("Data de modificação").font(.system(size: 12))
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(NovaTheme.card).cornerRadius(7)
            Spacer()
            HStack(spacing: 0) {
                Button { gridMode = true } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 12)).foregroundColor(gridMode ? .white : NovaTheme.sec)
                        .frame(width: 34, height: 30)
                        .background(gridMode ? NovaTheme.accent : NovaTheme.card)
                }
                Button { gridMode = false } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12)).foregroundColor(!gridMode ? .white : NovaTheme.sec)
                        .frame(width: 34, height: 30)
                        .background(!gridMode ? NovaTheme.accent : NovaTheme.card)
                }
            }
            .cornerRadius(7)
        }
        .padding(.horizontal, NovaTheme.gutter)
        .padding(.vertical, 10)
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                  spacing: 10) {
            ForEach(SampleProjects.all) { p in
                ProjectCard(project: p, height: 150, showMenu: true)
                    .onTapGesture { onOpen(p) }
            }
        }
        .padding(.horizontal, NovaTheme.gutter)
    }
}
