// The Swift Programming Language
// https://docs.swift.org/swift-book

//  TokenTextView.swift
//  TokenEditorView
//  Created by ZXL on 2025/8/28


import SwiftUI
import AppKit

// MARK: - NSTextView subclass to handle drag&drop of tags
// AppKit 组件， 继承NSTextView
@available(macOS 10.15, *)
protocol TokenDragDelegate {
    func TokenDragOperation(_ item:String) -> [Token]
}

@available(macOS 10.15, *)
public final class TokenNSTextView: NSTextView {
    
   
    var tokenDalegate: TokenDragDelegate?

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }
    // 重写NSTextView接收拖拽的逻辑
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard
        guard let items = pb.pasteboardItems else { return false }
        var inserted = false
        for item in items {
            // 发布代理到外层,用于预处理拖入的字符串
            if let s = item.string(forType: .string){
                if let tokens = tokenDalegate?.TokenDragOperation(s) {
                    //TODO: 预处理后，对tag和user类型分别处理
                    for token in tokens {
                        if token.source == .tag {
                            insertTagToken(token.text)
                        }else{
                            insertUserToken(token.text)
                        }
                    }
                    inserted = true
                }
            }
        }
        if inserted {
            (delegate as? TokenEditorView.Coordinator)?.syncTokensFromTextStorage()
        }
        return inserted
    }
    
    public override func paste(_ sender: Any?) {
        guard let coordinator = delegate as? TokenEditorView.Coordinator else {
            super.paste(sender)
            return
        }

        let pb = NSPasteboard.general
        super.paste(sender)
        coordinator.syncTokensFromTextStorage()
    }
    
    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let point = convert(sender.draggingLocation, from: nil)
        let idx = characterIndexForInsertion(at: point)
        setSelectedRange(NSRange(location: idx, length: 0))
        return .copy
    }

    private func insertAttributedAtCursor(_ attr: NSAttributedString) {
        let loc = selectedRange().location
        textStorage?.beginEditing()
        textStorage?.replaceCharacters(in: selectedRange(), with: attr)
        textStorage?.endEditing()
        setSelectedRange(NSRange(location: loc + attr.length, length: 0))
    }
    
    // 插入 tag（作为 NSTextAttachment）
    public func insertTagToken(_ text: String) {
        let attachment = NSTextAttachment()
        attachment.attachmentCell = TokenAttachmentCell(text: text)

        let attributed = NSAttributedString(attachment: attachment)

        let insertionLocation = selectedRange().location
        textStorage?.beginEditing()
        textStorage?.insert(attributed, at: insertionLocation)
        textStorage?.endEditing()

        setSelectedRange(NSRange(location: insertionLocation + 1, length: 0))
    }
    
    // 插入 tag（作为 NSTextAttachment）
    public func insertUserToken(_ text: String) {
        let attachment = NSTextAttachment()
        let attributed = NSAttributedString(string: text)
        let insertionLocation = selectedRange().location
        textStorage?.beginEditing()
        textStorage?.insert(attributed, at: insertionLocation)
        textStorage?.endEditing()
        setSelectedRange(NSRange(location: insertionLocation + text.count, length: 0))
    }
}

// MARK: - NSViewRepresentable wrapper
// SwiftUI 组件
@available(macOS 10.15, *)
public struct TokenEditorView: NSViewRepresentable{
    
    public typealias NSViewType = NSScrollView
    
    @Binding var tokens: [Token]
    @Binding var replaceAction: (((String) -> String) -> String)?
    var dragAction: ((String) -> [Token])
    
    public init(tokens: Binding<[Token]>,
                replaceAction: Binding<(((String) -> String) -> String)?>,
                dragAction: @escaping ((String) -> [Token])
    ) {
        self._tokens = tokens
        self._replaceAction = replaceAction
        self.dragAction = dragAction
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self, dragAction) }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let textView = TokenNSTextView(frame: .zero)
        textView.isEditable = true
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.tokenDalegate = context.coordinator
        textView.allowsUndo = true
        textView.isRichText = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = false // 关键修改
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        // 在这里把 闭包函数 绑定出去
        DispatchQueue.main.async {
            weak var weakCoord = context.coordinator
            replaceAction = { transform in
                weakCoord?.replaceString(using: transform) ?? ""
            }
        }
        return scrollView
    }

    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        if context.coordinator.textView == nil {
                    context.coordinator.textView = nsView.documentView as? NSTextView
                }
                guard let textView = context.coordinator.textView as? TokenNSTextView else { return }
                let coordinator = context.coordinator

                guard !coordinator.isProgrammaticUpdate else { return }

                // Compare by (source, text) only, ignore UUID/ids on your Token
                let currentShallow = coordinator.collectTokensShallow()
                let targetShallow = tokens.map { TokenKey(source: $0.source, text: $0.text) }
                guard currentShallow != targetShallow else { return }

                let oldRange = textView.selectedRange()

                coordinator.isProgrammaticUpdate = true
                textView.string = ""
                for token in tokens {
                    if token.source == .tag {
                        textView.insertTagToken(token.text)
                    } else {
                        textView.insertUserToken(token.text)
                    }
                }
                // try to restore caret safely
                let maxLoc = (textView.string as NSString).length
                let safeLoc = min(oldRange.location, maxLoc)
                textView.setSelectedRange(NSRange(location: safeLoc, length: 0))
                coordinator.isProgrammaticUpdate = false
        
    }


    // MARK: - Coordinator
    public class Coordinator: NSObject, NSTextViewDelegate, TokenDragDelegate {
       
        var isProgrammaticUpdate = false
        var parent: TokenEditorView
        weak var textView: NSTextView?
        var dragAction: ((String) -> [Token])

        init(_ parent: TokenEditorView, _ dragAction: @escaping ((String) -> [Token])) {
            self.parent = parent
            self.dragAction = dragAction
        }
        
        /// TokenDragDelegate
        func TokenDragOperation(_ item: String) -> [Token] {
            dragAction(item)
        }

        /// 从 textStorage 同步 tokens
        func syncTokensFromTextStorage() {
            guard let storage = textView?.textStorage else { return }
            var newTokens: [Token] = []
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? NSTextAttachment,
                   let cell = attachment.attachmentCell as? TokenAttachmentCell {
                    newTokens.append(Token(text: cell.tokenText, source: .tag))
                } else {
                    let substring = storage.attributedSubstring(from: range).string
                    if !substring.isEmpty {
                        newTokens.append(Token(text: substring, source: .user))
                    }
                }
            }
            parent.tokens = newTokens
        }
        
        // Collect shallow comparable keys (source+text) only
        func collectTokensShallow() -> [TokenKey] {
           guard let storage = textView?.textStorage else { return [] }
           var keys: [TokenKey] = []
           let fullRange = NSRange(location: 0, length: storage.length)
           storage.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
               if let attachment = attrs[.attachment] as? NSTextAttachment,
                  let cell = attachment.attachmentCell as? TokenAttachmentCell {
                   keys.append(TokenKey(source: .tag, text: cell.tokenText))
               } else {
                   let substring = storage.attributedSubstring(from: range).string
                   if !substring.isEmpty {
                       keys.append(TokenKey(source: .user, text: substring))
                   }
               }
           }
           return keys
        }
        
        /// 控制输入与删除
        public func textView(_ textView: NSTextView,
                      shouldChangeTextIn affectedCharRange: NSRange,
                      replacementString: String?) -> Bool {
            guard let storage = textView.textStorage else { return true }

            var hasAttachment = false
            storage.enumerateAttribute(.attachment, in: affectedCharRange) { value, _, _ in
                if value is NSTextAttachment { hasAttachment = true }
            }

            if hasAttachment {
                // 删除 token
                if (replacementString ?? "").isEmpty {
                    storage.beginEditing()
                    storage.replaceCharacters(in: affectedCharRange, with: "")
                    storage.endEditing()
                    syncTokensFromTextStorage()
                    textView.setSelectedRange(NSRange(location: affectedCharRange.location, length: 0))
                }
                return false
            }
            return true
        }

        /// 保证输入属性不会继承 token 样式
        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            textView.typingAttributes = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.textColor,
                .backgroundColor: NSColor.clear
            ]
            textView.textStorage?.enumerateAttributes(in: NSRange(location: 0, length: textView.textStorage!.length), options: []) { attrs, range, _ in
                if attrs[.attachment] == nil {
                    textView.textStorage?.setAttributes(textView.typingAttributes, range: range)
                }
            }
        }

        public func textDidChange(_ notification: Notification) {
            guard !isProgrammaticUpdate else { return }
            syncTokensFromTextStorage()
        }
        
        /// 生成转换后的字符串
        public func replaceString(using transform: (String) -> String) -> String {
            guard let storage = textView?.textStorage else { return "" }

            var result = ""
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
                if let attachment = attrs[.attachment] as? NSTextAttachment,
                   let cell = attachment.attachmentCell as? TokenAttachmentCell {
                    //将闭包返回的字符串装入cell中，再与结果合并
                    result += transform(cell.tokenText)
                } else {
                    result += storage.attributedSubstring(from: range).string
                }
            }
            return result
        }
    }
}

struct TokenKey: Equatable {
    let source: Token.Source
    let text: String
}
