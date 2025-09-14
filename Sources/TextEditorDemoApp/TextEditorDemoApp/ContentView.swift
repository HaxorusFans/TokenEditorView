//
//  ContentView.swift
//  TextEditor_test
//  Created by ZXL on 2025/8/27
        

// ContentView.swift
import SwiftUI
import TokenEditorView
@available(macOS 10.15, *)
struct ContentView: View {
    @State private var tokens: [Token] = []
    
    let tags = ["Apple", "Banana", "Orange", "SwiftUI"]
    @State private var replaceAction: (((String) -> String) -> String)?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags:").font(.headline)
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                        .onDrag { NSItemProvider(object: NSString(string: "∑\(tag)∆")) } //拖入编辑区时，添加“∑∆(option+w  option+j)”标记
                }
                Spacer()
            }
            .frame(width: 120)

            Divider()

            VStack(alignment: .leading) {
                Text("Editor:").font(.headline)
                TokenEditorView(tokens: $tokens, replaceAction: $replaceAction){str in
                    if str.hasPrefix("∑"), str.hasSuffix("∆") {
                        var res = String(str.dropFirst())
                        res = String(res.dropLast())
                        return [Token(text: res, source: .tag)]
                    }
                    
                    return [Token(text: str, source: .user)]
                }
                    .frame(minHeight: 30)
                    .border(Color.gray, width: 1)
                Spacer()
                Button {
                    if let getTransformed = replaceAction {
                        let result = getTransformed { $0.uppercased() }
                        print("Transformed String: \(result)")
                    }
                } label: {
                    Text("Uppercase Tokens")
                }
                
                Button {
                    tokens = []
                } label: {
                    Text("empty")
                }
                
                RichText(token: "Hello")

            }
            .padding()
            
        }
        .padding()
    }
}
