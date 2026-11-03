//
//  NovaTabBar.swift
//  Bottom nav: Início / Projetos / FAB roxo / Presets / Perfil
//

import SwiftUI

struct NovaTabBar: View {
    @Binding var tab: Tab

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabItem(.inicio,   title: "Início",   system: "house.fill")
                tabItem(.projetos, title: "Projetos", system: "folder.fill")
                Color.clear.frame(width: 60)  // slot do FAB
                tabItem(.presets,  title: "Presets",  system: "storefront")
                tabItem(.perfil,   title: "Perfil",   system: "person.crop.circle.fill")
            }
            .frame(height: 62)
            .background(NovaTheme.bg)
            .overlay(Rectangle().frame(height: 0.5).foregroundColor(NovaTheme.border), alignment: .top)

            // FAB roxo central
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        LinearGradient(colors: [NovaTheme.accent, NovaTheme.accent2],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: NovaTheme.accent.opacity(0.5), radius: 10, y: 6)
            }
            .offset(y: -16)
        }
    }

    @ViewBuilder
    private func tabItem(_ t: Tab, title: String, system: String) -> some View {
        let on = (tab == t)
        Button(action: { tab = t }) {
            VStack(spacing: 3) {
                Image(systemName: system)
                    .font(.system(size: 18))
                Text(title).font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(on ? NovaTheme.accent2 : NovaTheme.sec)
        }
    }
}
