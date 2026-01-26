//
//  HelpComponents.swift
//  DontBeAFK
//
//  Reusable components for help views
//

import SwiftUI

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.title2.bold())
            
            content()
                .font(.body)
        }
    }
}

struct BulletList: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(item)
                }
            }
        }
    }
}

struct NumberedList: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .trailing)
                    Text(item)
                }
            }
        }
    }
}

struct IntervalRecommendation: View {
    let range: String
    let description: String
    let useCase: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(range)
                .font(.headline)
            Text(description)
                .foregroundColor(.secondary)
            Text("Use case: \(useCase)")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TroubleshootingItem: View {
    let problem: String
    let solutions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(problem, systemImage: "exclamationmark.circle")
                .font(.headline)
            
            BulletList(items: solutions)
                .padding(.leading, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }
}
