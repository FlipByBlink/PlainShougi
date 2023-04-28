import SwiftUI

struct 📜履歴類セクション: View {
    var body: some View {
        Section {
            ブックマークメニューリンク()
            NavigationLink {
                📜履歴メニュー()
            } label: {
                Label("履歴", systemImage: "clock")
            }
            .disabled(局面モデル.履歴.isEmpty)
        }
    }
}

struct 📜履歴メニュー: View {
    @EnvironmentObject private var 📱: 📱アプリモデル
    @State private var 🚩履歴削除完了: Bool = false
    var body: some View {
        List {
            Section {
                Text("直近の約30局面を履歴として保存します")
                    .padding(8)
                    .contextMenu { self.削除ボタン() }
                    .accessibilityHidden(true)
            }
            ForEach(局面モデル.履歴.reversed(), id: \.更新日時) { 局面 in
                HStack {
                    局面プレビュー(局面)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(局面.更新日付表記)
                            .font(.title3)
                        Text(局面.更新時刻表記)
                            .font(.subheadline)
                        Spacer()
                        Button {
                            📱.履歴を復元する(局面)
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("復元")
                            }
                            .font(.body.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                        .dynamicTypeSize(...DynamicTypeSize.xLarge)
                    }
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .padding(.vertical, 8)
                }
                .padding()
            }
            if self.🚩履歴削除完了 { Text("これまでの履歴を削除しました") }
            if 局面モデル.履歴.isEmpty {
                Text("現在、履歴はありません")
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.default, value: self.🚩履歴削除完了)
        .navigationTitle("履歴")
    }
    private func 削除ボタン() -> some View {
        Button {
            局面モデル.履歴を全て削除する()
            self.🚩履歴削除完了 = true
            💥フィードバック.警告()
        } label: {
            Label("履歴を全て削除する", systemImage: "trash")
        }
        .accessibilityLabel("削除")
        .disabled(局面モデル.履歴.isEmpty)
    }
}

struct 📜ブックマーク保存ボタン: View {
    var タイトル: LocalizedStringKey
    @EnvironmentObject private var 📱: 📱アプリモデル
    var body: some View {
        Button {
            withAnimation { 📱.局面.現在の局面をブックマークする() }
            💥フィードバック.軽め()
        } label: {
            Label(self.タイトル, systemImage: "bookmark")
        }
    }
}

struct 📜ブックマーク復元ボタン: View {
    var タイトル: LocalizedStringKey
    @EnvironmentObject private var 📱: 📱アプリモデル
    @AppStorage("ブックマーク") private var ブックマークデータ: Data?
    private var 局面: 局面モデル? { 局面モデル.デコード(self.ブックマークデータ) }
    var body: some View {
        if let 局面 {
            Button {
                📱.履歴を復元する(局面)
            } label: {
                Label(self.タイトル, systemImage: "square.and.arrow.down")
            }
        }
    }
}

private struct ブックマークメニューリンク: View {
    var body: some View {
        NavigationLink {
            Self.コンテンツ()
        } label: {
            Label("ブックマーク", systemImage: "bookmark")
        }
    }
    private struct コンテンツ: View {
        @EnvironmentObject private var 📱: 📱アプリモデル
        @AppStorage("ブックマーク") private var ブックマークデータ: Data?
        private var 局面: 局面モデル? { 局面モデル.デコード(self.ブックマークデータ) }
        var body: some View {
            List {
                if let 局面 {
                    Section {
                        VStack(spacing: 20) {
                            局面プレビュー(局面)
                            📜ブックマーク復元ボタン(タイトル: "復元")
                                .font(.body.weight(.medium))
                                .buttonStyle(.bordered)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    } header: {
                        Text(局面.更新日付表記 + " " + 局面.更新時刻表記)
                    }
                    Section { 📜ブックマーク保存ボタン(タイトル: "現在の局面をブックマーク") }
                } else {
                    Label("ブックマークはありません", systemImage: "bookmark.slash")
                        .foregroundStyle(.secondary)
                    Section { 📜ブックマーク保存ボタン(タイトル: "現在の局面をブックマーク") }
                }
                Label("ブックマークに保存できる局面は1つだけです", systemImage: "1.circle")
            }
            .navigationTitle("ブックマーク")
            .animation(.default, value: self.ブックマークデータ)
        }
    }
}

private struct 局面プレビュー: View {
    @EnvironmentObject private var 📱: 📱アプリモデル
    private var 局面: 局面モデル
    private static let コマのサイズ: CGFloat = 20
    var body: some View {
        VStack {
            self.手駒プレビュー(局面, .玉側)
            self.盤面プレビュー(局面)
            self.手駒プレビュー(局面, .王側)
        }
    }
    private func 盤面プレビュー(_ 局面: 局面モデル) -> some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 9) { 行 in
                HStack(spacing: 0) {
                    ForEach(0 ..< 9) { 列 in
                        let 位置 = 行 * 9 + 列
                        if let 駒 = 局面.盤駒[位置] {
                            Text(局面.この駒の表記(.盤駒(位置), 📱.🚩English表記) ?? "🐛")
                                .underline(局面.この駒にはアンダーラインが必要(.盤駒(位置), 📱.🚩English表記))
                                .fontWeight(局面.直近の操作 == .盤駒(位置) ? .bold : .light)
                                .rotationEffect(駒.陣営 == .玉側 ? .degrees(180) : .zero)
                                .minimumScaleFactor(0.1)
                                .frame(width: Self.コマのサイズ, height: Self.コマのサイズ)
                        } else {
                            Color.clear
                                .frame(width: Self.コマのサイズ, height: Self.コマのサイズ)
                        }
                    }
                }
            }
        }
        .frame(width: Self.コマのサイズ * 9, height: Self.コマのサイズ * 9)
        .padding(2)
        .border(.primary, width: 0.66)
    }
    private func 手駒プレビュー(_ 局面: 局面モデル, _ 陣営: 王側か玉側か) -> some View {
        HStack {
            ForEach(駒の種類.allCases) {
                if let 表記 = 局面.この駒の表記(.手駒(陣営, $0), 📱.🚩English表記) {
                    Text(表記)
                        .fontWeight(.light)
                        .minimumScaleFactor(0.1)
                }
            }
        }
        .rotationEffect(陣営 == .玉側 ? .degrees(180) : .zero)
        .frame(width: Self.コマのサイズ * 9, height: Self.コマのサイズ)
    }
    init(_ ｷｮｸﾒﾝ: 局面モデル) { self.局面 = ｷｮｸﾒﾝ }
}
