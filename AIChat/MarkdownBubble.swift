//
//  MarkdownBubble.swift
//  AIChat
//
//  Created by Apple on 5/12/26.
//

import SwiftUI
import MarkdownUI

struct MarkdownBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        if isUser {
            Text(text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(
                    maxWidth: UIScreen.main.bounds.width * 0.75,
                    alignment: .trailing
                )
        } else {
            Markdown(text)
                .markdownTheme(.aiChat)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(
                    maxWidth: UIScreen.main.bounds.width * 0.80,
                    alignment: .leading
                )
        }
    }
}

// MARK: - Custom markdown theme
extension Theme {
    static let aiChat = Theme()
        .text {
            ForegroundColor(.primary)
            FontSize(15)
        }
        .strong {
            FontWeight(.semibold)
            ForegroundColor(.primary)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(13)
            ForegroundColor(.pink)
            BackgroundColor(Color(.systemGray4))
        }
        .codeBlock { config in
            ScrollView(.horizontal) {
                config.label
                    .relativeLineSpacing(.em(0.3))
                    .padding(14)
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(13)
                        ForegroundColor(Color(.systemGreen))
                    }
            }
            .background(Color(.systemGray6).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .markdownMargin(top: 6, bottom: 6)
        }
        .heading1 { config in
            config.label
                .relativeLineSpacing(.em(0.2))
                .markdownMargin(top: 8, bottom: 4)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(20)
                    ForegroundColor(.primary)
                }
        }
        .heading2 { config in
            config.label
                .markdownMargin(top: 6, bottom: 4)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(17)
                    ForegroundColor(.primary)
                }
        }
        .heading3 { config in
            config.label
                .markdownMargin(top: 4, bottom: 2)
                .markdownTextStyle {
                    FontWeight(.medium)
                    FontSize(15)
                    ForegroundColor(.primary)
                }
        }
        .listItem { config in
            config.label
                .markdownMargin(top: 2)
        }
        .blockquote { config in
            config.label
                .padding(.leading, 12)
                .overlay(
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 3),
                    alignment: .leading
                )
                .markdownTextStyle {
                    ForegroundColor(.secondary)
                    FontStyle(.italic)
                }
        }
}
