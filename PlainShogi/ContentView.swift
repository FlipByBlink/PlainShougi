import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            将棋View()
            🛠SharePlayインジケーターやメニューボタン()
        }
        .padding(🗄️固定値.全体パディング)
        .modifier(🛠非SharePlay時のメニューボタン())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .modifier(🛠メニューシート())
        .modifier(🗄️初回起動時に駒の動かし方の説明バナー())
        .modifier(🗄️MacCatalystでタイトルバー非表示())
        .modifier(🗄️自動スリープ無効化())
        .modifier(📣広告コンテンツ())
        .modifier(👥SharePlay環境構築())
        .overlay(alignment: .top) { 🚧フォントデバッグメニュー() }
    }
}
