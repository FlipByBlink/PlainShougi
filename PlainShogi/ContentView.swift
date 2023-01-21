import SwiftUI
import UniformTypeIdentifiers

// MARK: 仕様
// 手前が「王」、対面が「玉」。

struct ContentView: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    private let マスに対する段筋の大きさ: Double = 0.5
    private let 盤上と盤外の隙間: CGFloat = 4
    var body: some View {
        GeometryReader { 画面 in
            let マスの大きさ = self.マスの大きさを計算(画面.size)
            let 筋 = 筋表示(幅: マスの大きさ * self.マスに対する段筋の大きさ)
            let 段 = 段表示(高さ: マスの大きさ * self.マスに対する段筋の大きさ)
            let 上下反転 = 📱.🚩上下反転
            VStack(spacing: self.盤上と盤外の隙間) {
                盤外(.対面, マスの大きさ)
                VStack(spacing: 0) {
                    if !上下反転 { 筋 }
                    HStack(spacing: 0) {
                        if 上下反転 { 段 }
                        盤面(マスの大きさ)
                        if !上下反転 { 段 }
                    }
                    if 上下反転 { 筋 }
                }
                盤外(.手前, マスの大きさ)
            }
        }
        .padding()
    }
    private func マスの大きさを計算(_ 画面サイズ: CGSize) -> CGFloat {
        let 横基準 = 画面サイズ.width / (9 + self.マスに対する段筋の大きさ)
        let 縦基準 = (画面サイズ.height - self.盤上と盤外の隙間 * 2) / (11 + self.マスに対する段筋の大きさ)
        return min(横基準, 縦基準)
    }
}

struct 盤面: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    private let マスの大きさ: CGFloat
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ForEach(0 ..< 9) { 行 in
                HStack(spacing: 0) {
                    Divider()
                    ForEach(0 ..< 9) { 列 in
                        盤上のコマもしくはマス(行 * 9 + 列)
                        Divider()
                    }
                }
                Divider()
            }
        }
        .border(.primary, width: 枠線の太さ)
        .frame(width: self.マスの大きさ * 9, height: self.マスの大きさ * 9)
        .clipped()
    }
    init(_ ﾏｽﾉｵｵｷｻ: CGFloat) {
        self.マスの大きさ = ﾏｽﾉｵｵｷｻ
    }
}

struct 盤上のコマもしくはマス: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    @State private var ドラッグ中 = false
    private var 画面上での左上からの位置: Int
    private var 元々の位置: Int {
        📱.🚩上下反転 ? (80 - self.画面上での左上からの位置) : self.画面上での左上からの位置
    }
    private var 駒: 盤上の駒? { 📱.局面.盤駒[元々の位置] }
    private var 表記: String { 📱.この盤駒の表記(self.元々の位置) }
    private var 操作直後: Bool { 📱.この盤駒は操作直後(画面上での左上からの位置) }
    private var SとNを見分けるためのアンダーライン: Bool {
        (self.駒?.陣営 == .玉側) && (self.表記 == "S" || self.表記 == "N")
    }
    var body: some View {
        Group {
            if let 駒 {
                コマ(self.表記, self.$ドラッグ中, self.操作直後, self.SとNを見分けるためのアンダーライン)
                    .modifier(下向きに変える(駒.陣営, 📱.🚩上下反転))
                    .overlay { 駒を消すボタン(self.元々の位置) }
                    .onTapGesture(count: 2) { 📱.この駒を裏返す(self.元々の位置) }
                    .modifier(このコマが操作直後なら強調表示(self.画面上での左上からの位置))
                    .accessibilityHidden(true)
                    .onDrag {
                        振動フィードバック()
                        self.ドラッグ中 = true
                        return 📱.この盤駒をドラッグし始める(self.元々の位置)
                    //} preview: {
                    //    ドラッグプレビュー用コマ(self.表記, ⓖeometryProxy.size, 駒.陣営, 📱.🚩上下反転)
                    }
            } else { // ==== マス ====
                Color(.systemBackground)
            }
        }
        .onDrop(of: [.utf8PlainText], delegate: 📬盤上ドロップ(📱, self.元々の位置))
    }
    init(_ 画面上での左上からの位置: Int) {
        self.画面上での左上からの位置 = 画面上での左上からの位置
    }
}

struct 盤外: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    private var 立場: 手前か対面か
    private var 陣営: 王側か玉側か {
        switch (self.立場, 📱.🚩上下反転) {
            case (.手前, false): return .王側
            case (.対面, false): return .玉側
            case (.手前, true): return .玉側
            case (.対面, true): return .王側
        }
    }
    private var コマの大きさ: CGFloat
    private var 駒の並び順: [駒の種類] {
        self.立場 == .手前 ? 駒の種類.allCases : 駒の種類.allCases.reversed()
    }
    var body: some View {
        ZStack {
            Color(.systemBackground)
            HStack(spacing: 0) {
                ForEach(self.駒の並び順) { 職名 in
                    盤外のコマ(self.陣営, 職名, self.コマの大きさ)
                }
            }
            .frame(height: self.コマの大きさ)
            .frame(maxWidth: self.コマの大きさ * 12)
        }
        .onDrop(of: [UTType.utf8PlainText], delegate: 📬盤外ドロップ(📱, self.陣営))
        .overlay(alignment: self.立場 == .手前 ? .bottomLeading : .topTrailing) {
            手駒編集ボタン(self.陣営)
                .modifier(下向きに変える(self.陣営, 📱.🚩上下反転))
        }
    }
    init(_ ﾀﾁﾊﾞ: 手前か対面か, _ ｵｵｷｻ: CGFloat) {
        (self.立場, self.コマの大きさ) = (ﾀﾁﾊﾞ, ｵｵｷｻ)
    }
    enum 手前か対面か {
        case 手前, 対面
    }
}

struct 盤外のコマ: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    @State private var ドラッグ中 = false
    private var 陣営: 王側か玉側か
    private var 職名: 駒の種類
    private var コマの大きさ: CGFloat
    private var 駒の表記: String { 📱.この手駒の表記(self.陣営, self.職名) }
    private var 数: Int { 📱.局面.この手駒の数(self.陣営, self.職名) }
    private var 盤外上での表記: String? {
        switch self.数 {
            case 1: return self.駒の表記
            case 2...: return self.駒の表記 + self.数.description
            default: return nil
        }
    }
    private var 直近の操作として強調表示: Bool { 📱.この手駒は操作直後(self.陣営, self.職名) }
    var body: some View {
        if let 盤外上での表記 {
            HStack {
                Spacer(minLength: 0)
                コマ(盤外上での表記, self.$ドラッグ中, self.直近の操作として強調表示)
                    .frame(maxWidth: self.コマの大きさ * (self.数 >= 2 ? 1.5 : 1))
                    .modifier(下向きに変える(self.陣営, 📱.🚩上下反転))
                    .onDrag{
                        振動フィードバック()
                        self.ドラッグ中 = true
                        return 📱.この手駒をドラッグし始める(self.陣営, self.職名)
                    } preview: {
                        ドラッグプレビュー用コマ(self.駒の表記, self.コマの大きさ, self.陣営, 📱.🚩上下反転)
                    }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: self.コマの大きさ * 3)
        }
    }
    init(_ ｼﾞﾝｴｲ: 王側か玉側か, _ ｼｮｸﾒｲ: 駒の種類, _ ｺﾏﾉｵｵｷｻ: CGFloat) {
        (self.陣営, self.職名, self.コマの大きさ) = (ｼﾞﾝｴｲ, ｼｮｸﾒｲ, ｺﾏﾉｵｵｷｻ)
    }
}

struct コマ: View {
    @EnvironmentObject var 📱: 📱アプリモデル
    private var 表記: String
    @Binding private var ドラッグ中: Bool
    private var 操作直後: Bool
    private var 強調表示: Bool {
        self.操作直後 && !📱.🚩直近操作強調表示機能オフ
    }
    private var アンダーライン: Bool
    var body: some View {
        ZStack {
            Color(.systemBackground)
            Text(self.表記)
                .font(駒フォント)
                .fontWeight(self.強調表示 ? .bold : nil)
                .underline(self.アンダーライン)
                .minimumScaleFactor(0.1)
                .opacity(self.ドラッグ中 ? 0.25 : 1.0)
                .rotationEffect(.degrees(📱.🚩駒を整理中 ? 20 : 0))
                .onChange(of: self.ドラッグ中) { ⓝewValue in
                    if ⓝewValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeIn(duration: 1.5)) {
                                self.ドラッグ中 = false
                            }
                        }
                    }
                }
        }
    }
    init(_ ﾋｮｳｷ: String, _ ﾄﾞﾗｯｸﾞﾁｭｳ: Binding<Bool>, _ ｿｳｻﾁｮｸｺﾞ: Bool = false, _ ｱﾝﾀﾞｰﾗｲﾝ: Bool = false) {
        (self.表記, self._ドラッグ中, self.操作直後, self.アンダーライン) = (ﾋｮｳｷ, ﾄﾞﾗｯｸﾞﾁｭｳ, ｿｳｻﾁｮｸｺﾞ, ｱﾝﾀﾞｰﾗｲﾝ)
    }
}

struct 下向きに変える: ViewModifier {
    private var 陣営: 王側か玉側か
    private var 上下反転: Bool
    private var 🚩条件: Bool {
        (self.陣営 == .玉側) != 上下反転
    }
    func body(content: Content) -> some View {
        content
            .rotationEffect(self.🚩条件 ? .degrees(180) : .zero)
    }
    init(_ ｼﾞﾝｴｲ: 王側か玉側か, _ ｼﾞｮｳｹﾞﾊﾝﾃﾝ: Bool) {
        (self.陣営, self.上下反転) = (ｼﾞﾝｴｲ, ｼﾞｮｳｹﾞﾊﾝﾃﾝ)
    }
}

struct 成駒確認アラート: ViewModifier {
    @EnvironmentObject var 📱: 📱アプリモデル
    func body(content: Content) -> some View {
        content
            .alert("成り駒にしますか？", isPresented: $📱.🚩成駒確認アラートを表示) {
                Button("成る") {
                    if case .盤駒(let 位置) = 📱.局面.直近の操作 {
                        📱.この駒を裏返す(位置)
                    }
                }
                Button(role: .cancel) {
                    📱.🚩成駒確認アラートを表示 = false
                } label: {
                    Text("キャンセル")
                }
            } message: {
                if case .盤駒(let 位置) = 📱.局面.直近の操作 {
                    if let 駒 = 📱.局面.盤駒[位置]?.職名 {
                        if 📱.🚩English表記 {
                            Text(verbatim: 駒.English生駒表記 + " → " + (駒.English成駒表記 ?? "🐛"))
                        } else {
                            Text(verbatim: 駒.rawValue + " → " + (駒.成駒表記 ?? "🐛"))
                        }
                    }
                }
            }
    }
}

struct ドラッグプレビュー用コマ: View {
    private var 表記: String
    private var コマの大きさ: CGFloat
    private var 陣営: 王側か玉側か
    private var 上下反転: Bool
    var body: some View {
        ZStack {
            Color(.systemBackground)
            Text(self.表記)
                .font(駒フォント)
                .minimumScaleFactor(0.1)
        }
        .frame(width: self.コマの大きさ, height: self.コマの大きさ)
        .modifier(下向きに変える(self.陣営, self.上下反転))
    }
    init(_ ﾋｮｳｷ: String, _ ｺﾏﾉｵｵｷｻ: CGFloat, _ ｼﾞﾝｴｲ: 王側か玉側か, _ ｼﾞｮｳｹﾞﾊﾝﾃﾝ: Bool) {
        (self.表記, self.コマの大きさ, self.陣営, self.上下反転) = (ﾋｮｳｷ, ｺﾏﾉｵｵｷｻ, ｼﾞﾝｴｲ, ｼﾞｮｳｹﾞﾊﾝﾃﾝ)
    }
}

func 振動フィードバック() {
    UISelectionFeedbackGenerator().selectionChanged()
}

var 駒フォント: Font {
    switch UIDevice.current.userInterfaceIdiom {
        case .phone: return .title3
        case .pad: return .title
        default: return .title3
    }
}

var 段筋フォント: Font {
    switch UIDevice.current.userInterfaceIdiom {
        case .phone: return .caption
        case .pad: return .body
        default: return .caption
    }
}
