import SwiftUI

struct 🛠メニューボタン: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    var body: some View {
        if 📱.🚩駒を整理中 {
            整理完了ボタン()
        } else {
            Menu {
                🛠盤面初期化ボタン()
                🛠盤面整理開始ボタン()
                🛠移動直後強調表示クリアボタン()
                Button {
                    withAnimation { 📱.🚩上下反転.toggle() }
                } label: {
                    Label(📱.🚩上下反転 ? "上下反転を元に戻す" : "上下反転させる",
                          systemImage: "arrow.up.arrow.down")
                }
            } label: {
                Text("…")
                    .padding()
            } primaryAction: {
                📱.🚩メニューを表示 = true
                振動フィードバック()
            }
            .padding()
            .tint(.primary)
            .accessibilityLabel("Open menu")
        }
    }
}

struct 🛠アプリメニュー: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    var body: some View {
        NavigationView {
            List {
                Section {
                    Label("長押しして駒を持ち上げ、そのままスライドして移動させる", systemImage: "hand.draw")
                        .padding(.vertical, 8)
                } header: {
                    Text("あそび方")
                }
                .foregroundStyle(.primary)
                Section {
                    🛠盤面初期化ボタン()
                    🛠盤面整理開始ボタン()
                    🛠移動直後強調表示クリアボタン()
                }
                Section {
                    NavigationLink {
                        履歴List()
                    } label: {
                        Label("履歴", systemImage: "clock")
                    }
                }
                Section {
                    Toggle(isOn: $📱.🚩English表記) {
                        Label("English表記", systemImage: "p.square")
                    }
                    Toggle(isOn: $📱.🚩移動直後強調表示機能オフ) {
                        Label("移動直後の強調表示機能を無効にする", systemImage: "underline")
                    }
                    Toggle(isOn: $📱.🚩上下反転) {
                        Label("上下反転", systemImage: "arrow.up.arrow.down")
                    }
                } header: {
                    Text("オプション")
                }
                細かな使い方セクション()
                テキスト書き出し読み込みセクション()
                📣ADMenuLink()
                📄InformationMenuLink()
            }
            .navigationTitle("メニュー")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        📱.🚩メニューを表示 = false
                        振動フィードバック()
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                            .grayscale(1.0)
                            .padding(8)
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
        }
        .onDisappear { 📱.🚩メニューを表示 = false }
    }
}

struct 履歴List: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    @State private var 🚩履歴削除完了: Bool = false
    private let コマのサイズ: CGFloat = 20
    var body: some View {
        List {
            ForEach(局面モデル.履歴.reversed(), id: \.更新日時) { 局面 in
                HStack {
                    VStack {
                        手駒プレビュー(局面, .玉側)
                        盤面プレビュー(局面)
                        手駒プレビュー(局面, .王側)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(局面.更新日時?.formatted(.dateTime.day().month()) ?? "🐛")
                            .font(.title3)
                        Text(局面.更新日時?.formatted(.dateTime.hour().minute()) ?? "🐛")
                            .font(.subheadline)
                        Spacer()
                        Button {
                            📱.履歴を復元する(局面)
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .imageScale(.small)
                                Text("復元")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.1)
                    .padding(.vertical, 20)
                }
                .padding()
            }
            if 🚩履歴削除完了 {
                Text("これまでの履歴を削除しました。")
            }
            if 局面モデル.履歴.isEmpty {
                Text("現在、履歴はありません。")
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.default, value: self.🚩履歴削除完了)
        .navigationTitle("履歴")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    局面モデル.履歴を全て削除する()
                    self.🚩履歴削除完了 = true
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                } label: {
                    Image(systemName: "trash")
                        .imageScale(.small)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("削除")
                .disabled(局面モデル.履歴.isEmpty)
            }
        }
    }
    private func 盤面プレビュー(_ 局面: 局面モデル) -> some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 9) { 行 in
                HStack(spacing: 0) {
                    ForEach(0 ..< 9) { 列 in
                        let 位置 = 行 * 9 + 列
                        if let 駒 = 局面.盤駒[位置] {
                            let 表記 = 局面.盤上のこの駒の表記(位置, 📱.🚩English表記) ?? "🐛"
                            Text(表記)
                                .underline((駒.陣営 == .玉側) && (表記 == "S" || 表記 == "N"))
                                .fontWeight(局面.盤駒の通常移動直後の駒?.盤上の位置 == 位置 ? .bold : .light)
                                .rotationEffect(駒.陣営 == .玉側 ? .degrees(180) : .zero)
                                .minimumScaleFactor(0.1)
                                .frame(width: コマのサイズ, height: コマのサイズ)
                        } else {
                            Color.clear
                                .frame(width: コマのサイズ, height: コマのサイズ)
                        }
                    }
                }
            }
        }
        .frame(width: コマのサイズ * 9, height: コマのサイズ * 9)
        .padding(2)
        .border(.primary, width: 0.66)
    }
    private func 手駒プレビュー(_ 局面: 局面モデル, _ 陣営: 王側か玉側か) -> some View {
        HStack {
            ForEach(駒の種類.allCases) { 駒 in
                if let 数 = 局面.手駒[陣営]?.配分[駒] {
                    let 表記 = 📱.🚩English表記 ? 駒.English生駒表記 : 駒.rawValue
                    Text(表記 + 数.description)
                        .fontWeight(.light)
                        .minimumScaleFactor(0.1)
                }
            }
        }
        .frame(width: コマのサイズ * 9, height: コマのサイズ)
    }
}

struct 細かな使い方セクション: View {
    var body: some View {
        NavigationLink {
            List {
                Label("ダブルタップで盤上の駒を裏返す", systemImage: "rotate.right")
                    .padding(8)
                Section {
                    VStack {
                        Text("メニューボタンを長押しすると「初期化ボタン」や「整理ボタン」を呼び出せます。")
                            .minimumScaleFactor(0.1)
                        Image("MenuLongPress")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .border(.primary)
                            .padding(8)
                    }
                    .padding()
                }
                Section {
                    VStack {
                        Text("Dynamic Type に対応しているので、OSの設定に合わせて駒の字の大きさを変えたり太文字にしたりできます。")
                        Image("DynamicType")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 120)
                            .border(.primary)
                            .padding(8)
                    }
                    .padding()
                }
            }
            .navigationTitle("細かな使い方")
        } label: {
            Label("細かな使い方", systemImage: "magazine")
        }
    }
}

struct テキスト書き出し読み込みセクション: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    var body: some View {
        NavigationLink {
            List {
                Section {
                    Label("駒を他のアプリへドラッグして盤面をテキストとして書き出せます。", systemImage: "square.and.arrow.up")
                    テキスト変換プレビュー(フォルダー名: "TextExport", 枚数: 4)
                }
                .listRowSeparator(.hidden)
                Section {
                    Label("他のアプリからテキストを盤上にドロップして盤面を読み込めます。「☗」が先頭のテキストをドロップしてください。",
                          systemImage: "square.and.arrow.down")
                    テキスト変換プレビュー(フォルダー名: "TextImport", 枚数: 5)
                }
                .listRowSeparator(.hidden)
                Section {
                    Text(📱.現在の盤面をテキストに変換する())
                        .padding()
                        .accessibilityLabel("テキスト")
                        .textSelection(.enabled)
                } header: {
                    Text("テキスト書き出し例")
                }
            }
            .navigationTitle("テキスト機能")
        } label: {
            Label("テキスト書き出し/読み込み機能", systemImage: "square.and.arrow.up.on.square")
        }
    }
}

struct テキスト変換プレビュー: View {
    var フォルダー名: String
    var 枚数: Int
    private let 🕒timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    @State private var 表示中の画像: Int = 0
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                ForEach( 0 ..< self.枚数, id: \.self) { 番号 in
                    if 番号 <= self.表示中の画像 {
                        Image(self.フォルダー名 + "/" + 番号.description)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            ProgressView(value: Double(self.表示中の画像), total: Double(self.枚数 - 1))
                .grayscale(1)
                .padding(.horizontal)
                .accessibilityHidden(true)
        }
        .onReceive(🕒timer) { _ in
            if self.表示中の画像 == self.枚数 - 1 {
                self.表示中の画像 = 0
            } else {
                self.表示中の画像 += 1
            }
        }
        .animation(.default.speed(0.5), value: self.表示中の画像)
        .padding(8)
    }
}
