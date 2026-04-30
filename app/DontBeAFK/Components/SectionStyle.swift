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
            .liquidGlassSectionCard(cornerRadius: 10)
    }
}

extension View {
    func sectionStyle() -> some View {
        modifier(SectionStyle())
    }
}
