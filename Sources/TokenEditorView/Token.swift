//
//  Token.swift
//  TokenEditorView
//  Created by ZXL on 2025/8/27
        
import Foundation

public struct Token: Identifiable, Equatable {
    public enum Source {
        case tag
        case user
    }
    public let id = UUID()
    public init(text: String, source: Source) {
        self.text = text
        self.source = source
    }
    public var text: String
    public var source: Source
    
//    public static func ConvertTokensToDict(tokens: [Token]) -> [[String:String]] {
//        var res: [[String:String]] = []
//        for item in tokens {
//            let t: [String:String] = [
//                "source": item.source == .tag ? "tag" : "user",
//                "text": item.text
//            ]
//            res.append(t)
//        }
//        return res
//    }
}
