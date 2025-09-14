//
//  TokenText.swift
//  TokenEditorView
//  Created by ZXL on 2025/9/2
        

// RichText.swift
import SwiftUI
import AppKit

// MARK: - RichText View
@available(macOS 10.15, *)
public struct RichText: View {
    private let attributed: NSAttributedString

    // 普通文字初始化
    public init(_ string: String,
         font: NSFont = .systemFont(ofSize: 14),
         color: NSColor = .textColor) {
        self.attributed = NSAttributedString(
            string: string,
            attributes: [
                .font: font,
                .foregroundColor: color
            ]
        )
    }

    // 单个 token 初始化
    public init(token: String) {
        let attachment = NSTextAttachment()
        attachment.attachmentCell = TokenAttachmentCell(text: token)
        self.attributed = NSAttributedString(attachment: attachment)
    }

    // Token 数组初始化
    public init(tokens: [Token],
         font: NSFont = .systemFont(ofSize: 14),
         color: NSColor = .textColor) {
        let result = NSMutableAttributedString()

        for token in tokens {
            switch token.source {
            case .user:
                let attr = NSAttributedString(
                    string: token.text,
                    attributes: [
                        .font: font,
                        .foregroundColor: color
                    ]
                )
                result.append(attr)

            case .tag:
                let attachment = NSTextAttachment()
                attachment.attachmentCell = TokenAttachmentCell(text: token.text)
                let attr = NSAttributedString(attachment: attachment)
                result.append(attr)
            }
        }

        self.attributed = result
    }

    fileprivate init(attributed: NSAttributedString) {
        self.attributed = attributed
    }

    public var body: some View {
        AttributedLabel(attributed: attributed)
    }

    // 拼接运算符
    static func + (lhs: RichText, rhs: RichText) -> RichText {
        let result = NSMutableAttributedString()
        result.append(lhs.attributed)
        result.append(rhs.attributed)
        return RichText(attributed: result)
    }
}

// MARK: - AttributedLabel (Bridge Layer)
struct AttributedLabel: NSViewRepresentable {
    let attributed: NSAttributedString

    func makeNSView(context: Context) -> NSTextField {
        let label = NSTextField()
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.allowsEditingTextAttributes = true
        label.isSelectable = false
        return label
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.attributedStringValue = attributed
        nsView.sizeToFit()
    }
}
