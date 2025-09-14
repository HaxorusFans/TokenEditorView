# TokenEditorView & RichText (SwiftUI/macOS)

## 📌 项目简介

本项目提供一套适用于 **macOS SwiftUI** 的富文本 UI 组件：

* **TokenEditorView**：支持用户输入文字与 token（标签）的混排编辑器，支持拖拽、删除、双向绑定。
* **RichText**：类 SwiftUI `Text` 的组件，支持显示富文本与 token，可拼接组合，适合只读场景。

解决了 SwiftUI 原生 `Text` 仅能展示纯文本、无法满足复杂属性编辑需求的问题。

---

## ✨ 功能特性

* **富文本编辑**：在 `NSTextView` 上封装，支持文字 + token 混排。
* **标签化输入**：token 以 `NSTextAttachment` 的形式嵌入，光标不可进入 token 内部，保证整体性。
* **双向绑定**：`@Binding var tokens: [Token]` 与 `NSTextView.textStorage` 保持同步。
* **API 扩展**：提供闭包式 `replaceAction`，可一键替换所有 token 文本。
* **只读展示**：`RichText` 组件支持像 `Text` 一样拼接文字与 token。
* **跨平台可迁移**：基于 `NSAttributedString`，逻辑可复用到 iOS/macOS。

---

## 📐 数据模型

```swift
struct Token: Equatable {
    let text: String
    let source: Source
    
    enum Source {
        case user  // 普通用户输入
        case tag   // 标签/Token
    }
}
```

* **text**：展示的文本内容
* **source**：区分来源，保证渲染时样式一致
* 在 UI ↔ State 同步时，`NSTextAttachment` 映射为 `.tag`，普通字符串映射为 `.user`

---

## 🛠 技术实现

* **跨框架封装**：使用 `NSViewRepresentable` 将 `NSTextView` 引入 SwiftUI。
* **交互优化**：拦截光标与删除操作，避免光标进入 token 内部或删除残留空格。
* **视觉一致性**：自定义 `TokenAttachmentCell`，保证 token 与普通文字基线对齐。

---

## 🚀 使用示例

### 1. 可编辑输入框

```swift
@State private var tokens: [Token] = []
@State private var replaceAction: (((String) -> String) -> String)?
TokenEditorView(tokens: $tokens, replaceAction: $replaceAction){str in
    if str.hasPrefix("∑"), str.hasSuffix("∆") {
        var res = String(str.dropFirst())
        res = String(res.dropLast())
        return [Token(text: res, source: .tag)]
    }
    return [Token(text: str, source: .user)]
}
```

### 2. 一键替换

```swift
@State private var replaceAction: (((String) -> String) -> String)?
Button {
    if let getTransformed = replaceAction {
        let result = getTransformed { $0.uppercased() }
        print("Transformed String: \(result)")
    }
} label: {
    Text("Uppercase Tokens")
}
```

### 3. 富文本展示

```swift
let tokens: [Token] = [
    Token(text: "Hello", source: .user),
    Token(text: "SwiftUI", source: .tag),
    Token(text: "World", source: .user)
]

RichText(tokens: tokens)
    .padding()
```
