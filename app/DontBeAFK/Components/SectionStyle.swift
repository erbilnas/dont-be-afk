//
//  SectionStyle.swift
//  DontBeAFK
//
//  Section style modifier for Apple-like sections
//

import SwiftUI

struct SectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
            }
    }
}

extension View {
    func sectionStyle() -> some View {
        modifier(SectionStyle())
    }
}
