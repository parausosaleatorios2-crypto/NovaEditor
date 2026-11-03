//
//  EffectBrowserView.swift
//  Tela 6 — Navegador de efeito (grid de categorias coloridas).
//

import SwiftUI

struct EffectCategory: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let gradient: LinearGradient
}

enum EffectData {
    // 18 categorias — nomes e contagens LITERAIS do print 6+7
    static let categories: [EffectCategory] = [
        .init(name: "Cor",                 count: 49, gradient: grad("2A1A2A","1A3A5A")),
        .init(name: "Magic Bullet Looks",  count: 22, gradient: grad("F5A85A","E07A3A")),
        .init(name: "Desfoque",            count: 25, gradient: grad("2A3A5A","3A4A7A")),
        .init(name: "Tempo",               count:  1, gradient: grad("8A2A2A","C04050")),
        .init(name: "Distorção",           count: 56, gradient: grad("1A3A4A","0A4A6A")),
        .init(name: "Estilizar",           count: 88, gradient: grad("1A2A4A","2A3A6A")),
        .init(name: "Recorte",             count: 20, gradient: grad("3A2A4A","5A3A7A")),
        .init(name: "Procedural",          count: 20, gradient: grad("4A2A6A","6A4A8A")),
        .init(name: "Repetição",           count:  5, gradient: grad("1A2A4A","3A4A7A")),
        .init(name: "3D",                  count:  4, gradient: grad("1A1A2A","3A2A5A")),
        .init(name: "Texto",               count:  4, gradient: grad("3A3A5A","5A5A8A")),
        .init(name: "Áudio",               count:  7, gradient: grad("1A5A5A","2A7A7A")),
        .init(name: "Opacidade",           count:  3, gradient: grad("4A4A5A","6A6A7A")),
        .init(name: "Outros",              count:  1, gradient: grad("5A5A5A","7A7A7A")),
        .init(name: "Expressao",           count:  5, gradient: grad("4A4A5A","6A6A7A")),
        .init(name: "Gerar",               count: 13, gradient: grad("5A5A7A","7A7A9A")),
    ]
    static let trending = ["Luz profunda","Vidro líquido","Feixe de ene…","Raio",
                           "Rastreador d…","Risco anamó…"]
    static let recent   = ["Looks: Spot Exposure","Looks: Pop","Saturação/vibração","Copiar fundo"]
    static let totalInCatalog = 316
    static func grad(_ a: String, _ b: String) -> LinearGradient {
        LinearGradient(colors: [Color(hex: a), Color(hex: b)], startPoint: .leading, endPoint: .trailing)
    }
}

struct EffectBrowserView: View {
    let onBack: () -> Void
    let onSearch: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            head
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    trending
                    recent
                    categories
                    Text("\(EffectData.totalInCatalog) efeitos no catálogo")
                        .font(.system(size: 11)).foregroundColor(NovaTheme.sec)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 14)
                }
                .padding(.horizontal, NovaTheme.gutter)
                .padding(.top, 12)
            }
        }
        .background(NovaTheme.bg)
    }

    private var head: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "xmark").foregroundColor(.white).font(.system(size: 17, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text("Navegador de efeito").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            Spacer()
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(NovaTheme.greenAdd).font(.system(size: 17, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, NovaTheme.gutter).padding(.vertical, 12)
    }

    private var trending: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(EffectData.trending, id: \.self) { name in
                effectCell(name: name)
            }
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "clock").foregroundColor(.white).font(.system(size: 11))
                Text("Usados recentemente").font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(EffectData.recent, id: \.self) { name in
                    recentCell(name: name, isLast: name == "Copiar fundo")
                }
            }
        }
    }

    private var categories: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
            ForEach(EffectData.categories) { cat in
                ZStack(alignment: .bottomTrailing) {
                    cat.gradient
                    HStack {
                        Text(cat.name).font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                            .padding(.horizontal, 14)
                        Spacer()
                    }
                    Text("\(cat.count)").font(.system(size: 11)).foregroundColor(.white.opacity(0.9))
                        .padding([.trailing, .bottom], 10)
                }
                .frame(height: 72)
                .cornerRadius(9)
                .onTapGesture { onSearch() }
            }
        }
    }

    private func effectCell(name: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 9).fill(Color(hex:"2A1E4A"))
            Text("NOVA").font(.system(size: 11, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(NovaTheme.accent).cornerRadius(3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            Text(name).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                .lineLimit(1).padding(6)
        }
        .aspectRatio(1/1.1, contentMode: .fit)
    }

    private func recentCell(name: String, isLast: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            if isLast {
                Rectangle().fill(Color(hex:"AAAAAA"))
                    .overlay(Text("NOVA").font(.system(size: 11, weight: .black))
                        .foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(NovaTheme.accent).cornerRadius(3))
            } else {
                LinearGradient(colors: [Color(hex:"F0A85A"),Color(hex:"6B55E0"),Color(hex:"50A070"),Color(hex:"F0A85A"),Color(hex:"5050E0")],
                               startPoint: .leading, endPoint: .trailing)
            }
            Text(name).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                .lineLimit(2).padding(6)
                .shadow(radius: 1)
        }
        .aspectRatio(1/1.1, contentMode: .fit)
        .cornerRadius(9)
    }
}
