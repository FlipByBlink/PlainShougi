import SwiftUI

struct 共有メニューリンク: View {
    var body: some View {
        NavigationLink {
            List {
                Section {
                    テキスト共有メニューコンポーネンツ()
                } header: {
                    Text("テキスト")
                } footer: {
                    Text("読み込むテキストは先頭の文字が「☗」である必要があります")
                }
                Section {
                    画像共有メニューコンポーネンツ()
                } header: {
                    Text("画像")
                }
            }
            .headerProminence(.increased)
            .navigationTitle("盤面を共有")
        } label: {
            Label("盤面を共有", systemImage: "square.and.arrow.up")
        }
    }
}
