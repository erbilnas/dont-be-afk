//
//  LogView.swift
//  DontBeAFK
//
//  Log viewer sheet
//

import SwiftUI
import AppKit

struct LogView: View {
    @EnvironmentObject var controller: ScriptController
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Logs", systemImage: "doc.text")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .liquidGlassToolbarStrip()
            
            Divider()
            
            ScrollView {
                Text(controller.getLogs())
                    .font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .foregroundColor(.primary)
            }
            .scrollContentBackground(.hidden)
            .background(Color(NSColor.textBackgroundColor).opacity(0.55))
        }
        .frame(width: 600, height: 450)
    }
}
