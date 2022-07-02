
import Combine
import SwiftUI
import UniformTypeIdentifiers

//FIXME: テキスト書き出し読み込み機能未実装

class 📱AppModel: ObservableObject {
    
    @Published var 駒の配置: [Int: 盤上の駒] = 初期配置
    
    @Published var 手駒: [王側か玉側か: 手持ちの駒] = 空の手駒
    
    
    @AppStorage("English表記") var 🚩English表記: Bool = false
    
    
    var 現状: 状況 = .駒を持ち上げていない
    
    var 持ち上げられた駒の元々の位置: Int? = nil
    
    var 持ち上げられた手駒: (陣営: 王側か玉側か, 職名: 駒の種類)? = nil
    
    
    func 盤上の駒を持ち上げる(_ 位置: Int) -> NSItemProvider {
        持ち上げられた駒の元々の位置 = 位置
        現状 = .盤上の駒を持ち上げている
        return 外部書き出し用のテキストを準備する()
    }
    
    
    func 手駒を持ち上げる(_ 陣営: 王側か玉側か, _ 職名: 駒の種類) -> NSItemProvider {
        持ち上げられた手駒 = (陣営, 職名)
        現状 = .手駒を持ち上げている
        return 外部書き出し用のテキストを準備する()
    }
    
    
    func 駒をここに置く(_ 置いた位置: Int, _ 📦ItemProvider: [NSItemProvider]) -> Bool {
        
        アプリ外部からのドロップかどうか確認する(📦ItemProvider)
        
        switch 現状 {
            case .盤上の駒を持ち上げている:
                guard let 出発地点 = 持ち上げられた駒の元々の位置 else { return false }
                if 置いた位置 == 出発地点 { return false }
                
                if let 先客 = 駒の配置[置いた位置] {
                    if 先客.陣営 == 駒の配置[出発地点]?.陣営 { return true }
                    
                    手駒[駒の配置[出発地点]!.陣営]?.一個増やす(先客.職名)
                }
                
                駒の配置.updateValue(駒の配置[出発地点]!, forKey: 置いた位置)
                駒の配置.removeValue(forKey: 出発地点)
                
                持ち上げられた駒の元々の位置 = nil
                駒を移動させたらログを更新する()
                振動フィードバック()
            case .手駒を持ち上げている:
                guard let 駒 = 持ち上げられた手駒 else { return false }
                if 駒の配置[置いた位置] != nil { return false }
                
                駒の配置.updateValue(盤上の駒(駒.陣営, 駒.職名), forKey: 置いた位置)
                
                手駒[駒.陣営]?.一個減らす(駒.職名)
                
                持ち上げられた手駒 = nil
                駒を移動させたらログを更新する()
                振動フィードバック()
            case .駒を持ち上げていない:
                Task {
                    do {
                        guard let 📦 = 📦ItemProvider.first else { return }
                        let 🅂ecureCoding = try await 📦.loadItem(forTypeIdentifier: UTType.utf8PlainText.identifier)
                        guard let 💾 = 🅂ecureCoding as? Data else { return }
                        if let 📃 = String(data: 💾, encoding: .utf8) {
                            if 📃.first == "☗" {
                                DispatchQueue.main.async {
                                    self.このテキストを盤面に反映する(📃)
                                }
                            }
                        }
                    } catch {
                        print("==== Error: 📦.loadItem ====")
                        print(error)
                    }
                }
        }
        
        return true
    }
    
    
    func 盤上のこの駒の表記(_ 駒: 盤上の駒) -> String {
        if 駒.成り {
            return 🚩English表記 ? 駒.職名.English成駒表記! : 駒.職名.成駒表記!
        } else {
            if 駒.陣営 == .玉側 && 駒.職名 == .王 {
                return 🚩English表記 ? "K" : "玉"
            } else {
                return 🚩English表記 ? 駒.職名.English生駒表記 : 駒.職名.rawValue
            }
        }
    }
    
    
    func この手駒の表記(_ 陣営: 王側か玉側か, _ 職名: 駒の種類) -> String {
        if 陣営 == .玉側 && 職名 == .王 {
            return 🚩English表記 ? "K" : "玉"
        } else {
            return 🚩English表記 ? 職名.English生駒表記 : 職名.rawValue
        }
    }
    
    
    func この手駒の数(_ 陣営: 王側か玉側か, _ 職名: 駒の種類) -> Int {
        手駒[陣営]?.個数(職名) ?? 0
    }
    
    
    func 盤面を初期化する() {
        駒の配置 = 初期配置
        手駒 = 空の手駒
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    
    func アプリ外部からのドロップかどうか確認する(_ 📦ItemProvider: [NSItemProvider]) {
        guard let 📦 = 📦ItemProvider.first else { return }
        
        if let 🏷 = 📦.suggestedName {
            if 🏷 != "アプリ内でのコマ移動です" {
                現状 = .駒を持ち上げていない
                print("📦.suggestedName: ", 🏷)
            }
        } else {
            現状 = .駒を持ち上げていない
        }
    }
    
    
    // ==============================================================
    // ================ 以下、テキスト書き出し読み込み機能 ================
    func 駒を移動させたらログを更新する() {
        let 🗄 = UserDefaults.standard
        var セーブ用_駒の配置: [String: [String]] = [:]
        var セーブ用_手駒: [String: [String: String]] = ["王側": [:], "玉側": [:]]

        駒の配置.forEach { (位置: Int, 駒: 盤上の駒) in
            セーブ用_駒の配置.updateValue([駒.陣営.rawValue, 駒.職名.rawValue, 駒.成り.description], forKey: 位置.description)
        }

        王側か玉側か.allCases.forEach { 陣営 in
            手駒[陣営]?.配分.forEach { (職名: 駒の種類, 数: Int) in
                セーブ用_手駒[陣営.rawValue]?[職名.rawValue] = 数.description
            }
        }

        🗄.set(セーブ用_駒の配置, forKey: "駒の配置")
        🗄.set(セーブ用_手駒, forKey: "手駒")
    }
    
    
    init() {
        以前アプリ起動した際のログを読み込む()
    }
    
    func 以前アプリ起動した際のログを読み込む() {
        let 🗄 = UserDefaults.standard

        if let ロード用_駒の配置 = 🗄.dictionary(forKey: "駒の配置") as? [String: [String]] {
            if let ロード用_手駒 = 🗄.dictionary(forKey: "手駒") as? [String: [String: String]] {
                駒の配置 = [:]
                手駒 = 空の手駒

                ロード用_駒の配置.forEach { (位置テキスト: String, 駒テキスト: [String]) in
                    if let 陣営 = 王側か玉側か(rawValue: 駒テキスト[0]) {
                        if let 職名 = 駒の種類(rawValue: 駒テキスト[1]) {
                            if let 位置 = Int(位置テキスト) {
                                駒の配置.updateValue(盤上の駒(陣営, 職名), forKey: 位置)
                            }
                        }
                    }
                }

                王側か玉側か.allCases.forEach { 陣営 in
                    if let 一方の手駒テキスト = ロード用_手駒[陣営.rawValue] {
                        一方の手駒テキスト.forEach { (職名テキスト: String, 数テキスト: String) in
                            if let 職名 = 駒の種類(rawValue: 職名テキスト) {
                                if let 数 = Int(数テキスト) {
                                    手駒[陣営]?.配分.updateValue(数, forKey: 職名)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func 外部書き出し用のテキストを準備する() -> NSItemProvider {
        let 📃 = 現在の盤面をテキストに変換する()
        let 📦 = NSItemProvider(object: 📃 as NSItemProviderWriting)
        📦.suggestedName = "アプリ内でのコマ移動です"
        return 📦
    }
    
    
    //FIXME: 成駒が未実装
    //FIXME: Englishオプションが未実装
    func 現在の盤面をテキストに変換する() -> String {
        var 📃 = "☗"

        駒の種類.allCases.forEach { 例 in
            手駒[.玉側]?.配分.forEach { (職名: 駒の種類, 数: Int) in
                if 例 == 職名 {
                    📃 += 🚩English表記 ? 駒をEnglishプレーンテキストに変換(職名) + "͙" : 職名.rawValue + "͙"

                    if 数 >= 2 {
                        📃 += 数.description
                    }
                }
            }
        }

        📃 += "\n－－－－－－－－－\n"

        for 行 in 0 ..< 9 {
            for 列 in 0 ..< 9 {
                if let 駒 = self.駒の配置[行*9+列] {
                    📃 += 🚩English表記 ? 駒をEnglishプレーンテキストに変換(駒.職名, 駒.成り) : 駒.職名.rawValue

                    if 駒.陣営 == .玉側 {
                        📃 += "͙"
                    }
                } else {
                    📃 += "　"
                }
            }
            📃 += "\n"
        }

        📃 += "－－－－－－－－－\n☖"

        駒の種類.allCases.forEach { 例 in
            手駒[.王側]?.配分.forEach { (職名: 駒の種類, 数: Int) in
                if 例 == 職名 {
                    📃 += 🚩English表記 ? 駒をEnglishプレーンテキストに変換(職名) : 職名.rawValue

                    if 数 >= 2 {
                        📃 += 数.description
                    }
                }
            }
        }

        return 📃
    }
    
    
    //FIXME: 成駒が未実装
    //FIXME: Englishオプションが未実装
    func このテキストを盤面に反映する(_ 📃: String) {
        駒の配置 = [:]
        手駒 = 空の手駒

        var 改行数: Int = 0
        var 列: Int = 0
        var 読み込み中の手駒の種類: 駒の種類 = .歩

        for 字区切り in 📃 {
            if 字区切り == "\n" {
                改行数 += 1
                列 = 0
                continue
            }

            let 駒テキスト = 字区切り.description

            switch 改行数 {
                case 0:
                    if let 数 = Int(駒テキスト) {
                        手駒[.玉側]?.配分[読み込み中の手駒の種類] = 数
                    } else {
                        駒の種類.allCases.forEach { 職名 in
//                            if 駒テキスト == 職名.rawValue + "͙" || 駒テキスト == 職名.Englishプレーンテキスト + "͙" {
                            if 駒テキスト == 職名.rawValue + "͙" {
                                手駒[.玉側]?.配分[職名] = 1

                                読み込み中の手駒の種類 = 職名
                            }
                        }
                    }
                case 1...11:
                    駒の種類.allCases.forEach { 職名 in
                        let 位置 = ( 改行数 - 2 ) * 9 + 列

//                        if 駒テキスト == 職名.rawValue || 駒テキスト == 職名.Englishプレーンテキスト {
                        if 駒テキスト == 職名.rawValue {
                            駒の配置.updateValue(盤上の駒(.王側, 職名), forKey: 位置)
                        }

//                        if 駒テキスト == 職名.rawValue + "͙" || 駒テキスト == 職名.Englishプレーンテキスト + "͙" {
                        if 駒テキスト == 職名.rawValue + "͙" {
                            駒の配置.updateValue(盤上の駒(.玉側, 職名), forKey: 位置)
                        }
                    }
                case 12:
                    if let 数 = Int(駒テキスト) {
                        手駒[.王側]?.配分[読み込み中の手駒の種類] = 数
                    } else {
                        駒の種類.allCases.forEach { 職名 in
//                            if 駒テキスト == 職名.rawValue || 駒テキスト == 職名.Englishプレーンテキスト {
                            if 駒テキスト == 職名.rawValue {
                                手駒[.王側]?.配分[職名] = 1

                                読み込み中の手駒の種類 = 職名
                            }
                        }
                    }
                default: break
            }

            列 += 1
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}


func 駒をEnglishプレーンテキストに変換(_ 職名: 駒の種類, _ 成り: Bool = false) -> String {
    switch 職名 {
        case .歩: return 成り ? "ｐ" : "Ｐ"
        case .角: return 成り ? "ｂ" : "Ｂ"
        case .飛: return 成り ? "ｒ" : "Ｒ"
        case .香: return 成り ? "ｌ" : "Ｌ"
        case .桂: return 成り ? "ｎ" : "Ｎ"
        case .銀: return 成り ? "ｓ" : "Ｓ"
        case .金: return "Ｇ"
        case .王: return "Ｋ"
    }
}


//FIXME: >==== Error: 📦.loadItem ====
//> [Pasteboard] Could not retrieve data representation of type public.utf8-plain-text. Error: Error Domain=NSCocoaErrorDomain Code=4099 "The connection to service created from an endpoint was invalidated from this process." UserInfo={NSDebugDescription=The connection to service created from an endpoint was invalidated from this process.}
//> Error Domain=NSItemProviderErrorDomain Code=-1000 "Data transfer has been cancelled." UserInfo={NSLocalizedDescription=Data transfer has been cancelled.}

//FIXME: >==== Error: 📦.loadItem ====
//> Error Domain=NSItemProviderErrorDomain Code=-1000 "Cannot load representation of type public.text" UserInfo={NSLocalizedDescription=Cannot load representation of type public.text, NSUnderlyingError=0x283f97de0 {Error Domain=PBErrorDomain Code=0 "Cannot load representation of type public.utf8-plain-text" UserInfo={NSLocalizedDescription=Cannot load representation of type public.utf8-plain-text, NSUnderlyingError=0x283f945a0 {Error Domain=NSCocoaErrorDomain Code=4097 "connection to service with pid 68717 created from an endpoint" UserInfo={NSDebugDescription=connection to service with pid 68717 created from an endpoint}}}}}
