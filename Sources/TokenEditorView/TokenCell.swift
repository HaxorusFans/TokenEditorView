//
//  TokenCell.swift
//  TokenEditorView
//  Created by ZXL on 2025/8/28
import SwiftUI
import AppKit

public final class TokenAttachmentCell: NSTextAttachmentCell {
    let tokenText: String
    let myFont: NSFont = .systemFont(ofSize: 12)
    
    init(text: String) {
        self.tokenText = text
        super.init(imageCell: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func cellSize() -> NSSize {
        let textSize = (tokenText as NSString).size(withAttributes: [.font: myFont])
        return NSSize(width: textSize.width + 12, height: textSize.height + 6)
    }
    
    /// 关键：让 token 的中线对齐到文字的中线
    public override func cellBaselineOffset() -> NSPoint {
        let ascent = myFont.ascender
        let descent = abs(myFont.descender)
        let textMiddle = (ascent - descent) / 2
        let cellMiddle = cellSize().height / 2
        let offsetY = textMiddle - cellMiddle
        return NSPoint(x: 0, y: offsetY)
    }

    public override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        let path = NSBezierPath(roundedRect: cellFrame, xRadius: 6, yRadius: 6)
        NSColor.systemPurple.withAlphaComponent(0.4).setFill()
        path.fill()
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: myFont,
            .foregroundColor: NSColor.labelColor
        ]
        let textSize = (tokenText as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: cellFrame.origin.x + 6,
            y: cellFrame.origin.y + (cellFrame.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (tokenText as NSString).draw(in: textRect, withAttributes: attrs)
    }
}
