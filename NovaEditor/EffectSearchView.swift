//
//  EffectSearchView.swift
//  Tela 7 — Busca de efeito. Lista detalhada "Cor 49" com cards 3 colunas.
//

import SwiftUI
import NovaRenderKit

struct Effect: Identifiable {
    let id = UUID()
    let name: String
    let desc: String
    let tag: Tag?
    let implemented: Bool
    enum Tag: String {
        case ae = "Ae", am = "AM", node = "Node"
        var color: Color {
            switch self {
            case .ae:   return Color(hex:"4A4CC0")
            case .am:   return Color(hex:"2FA870")
            case .node: return Color(hex:"454555")
            }
        }
    }
}

enum CorEffects {
    static let all: [Effect] = [
        .init(name: "Apply Color LUT",    desc: "Aplica um LUT .cube à camada",                     tag: .ae,   implemented: true),
        .init(name: "Balanço de cor",      desc: "Temperatura, matiz e correção por faix…",         tag: nil,   implemented: true),
        .init(name: "Brilho e contraste",  desc: "Ajusta o brilho e o contraste da cama…",          tag: nil,   implemented: true),
        .init(name: "Brilho/contraste (…", desc: "Ajusta o brilho e o contraste da camada",         tag: .am,   implemented: true),
        .init(name: "Color Grading (No…",  desc: "Rodas Lift, Gamma e Gain, curvas de ma…",         tag: .node, implemented: true),
        .init(name: "Colorama",            desc: "Troca cada tom da imagem por uma c…",             tag: .ae,   implemented: true),
        .init(name: "Colorizar",           desc: "Muda a cor da camada, mantendo…",                 tag: .am,   implemented: true),
        .init(name: "Cor Quente",          desc: "Remapeia o brilho da camada numa ram…",           tag: .am,   implemented: true),
        .init(name: "Cor de preenchim…",   desc: "Pinta a camada de uma cor, mantendo…",            tag: .node, implemented: true),
    ]
}

struct EffectSearchView: View {
    let onBack: () -> Void
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            head
            searchBar
            ScrollView {
                sectionTitle
                grid
                Color.clear.frame(height: 20)
            }
        }
        .background(NovaTheme.bg)
    }

    private var head: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "arrow.left").foregroundColor(.white).font(.system(size: 17, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text("Navegador de efeito").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            Spacer()
            Image(systemName: "magnifyingglass").foregroundColor(NovaTheme.greenAdd).font(.system(size: 17, weight: .semibold))
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, NovaTheme.gutter).padding(.vertical, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(NovaTheme.sec).font(.system(size: 13))
            TextField("Buscar por nome, uso ou palavra-chave", text: $query)
                .font(.system(size: 13)).foregroundColor(.white)
        }
        .padding(.horizontal, 12).frame(height: 40)
        .background(NovaTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(NovaTheme.greenAdd, lineWidth: 1.5))
        .cornerRadius(9)
        .padding(.horizontal, NovaTheme.gutter).padding(.vertical, 8)
    }

    private var sectionTitle: some View {
        HStack(spacing: 8) {
            Text("Cor").font(.system(size: 15, weight: .heavy)).foregroundColor(.white)
            Text("49").font(.system(size: 11)).foregroundColor(NovaTheme.sec)
            Rectangle().fill(NovaTheme.border).frame(height: 1).padding(.leading, 10)
        }
        .padding(.horizontal, NovaTheme.gutter)
        .padding(.vertical, 10)
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(CorEffects.all) { e in effectCell(e) }
        }
        .padding(.horizontal, NovaTheme.gutter)
    }

    private func effectCell(_ e: Effect) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // thumb estilizado — barras RGB + círculo laranja do estilo real
                LinearGradient(stops: [
                    .init(color: Color(hex:"9D4B8A"), location: 0),
                    .init(color: Color(hex:"F0A85A"), location: 0.1),
                    .init(color: Color(hex:"50A070"), location: 0.3),
                    .init(color: Color(hex:"4B50E0"), location: 0.6),
                    .init(color: Color(hex:"9D4B8A"), location: 1.0),
                ], startPoint: .leading, endPoint: .trailing)
                Circle().fill(Color(hex:"F0A07C")).frame(width: 25, height: 25)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                if let t = e.tag {
                    Text(t.rawValue).font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1).background(t.color).cornerRadius(3)
                        .padding(5)
                }
                if e.implemented {
                    Text("●").font(.system(size: 11)).foregroundColor(NovaTheme.greenAdd)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(5)
                }
            }
            .frame(height: 70)
            VStack(alignment: .leading, spacing: 3) {
                Text(e.name).font(.system(size: 11, weight: .bold)).foregroundColor(.white).lineLimit(1)
                Text(e.desc).font(.system(size: 9.5)).foregroundColor(NovaTheme.sec)
                    .lineLimit(2).frame(height: 22, alignment: .top)
            }
            .padding(.horizontal, 8).padding(.vertical, 7)
        }
        .background(NovaTheme.card).cornerRadius(9)
    }
}
