//
//  PDFExportService.swift
//  AIChat
//
//  Created by Apple on 5/21/26.
//


import Foundation
import UIKit
import PDFKit

class PDFExportService {
    
    // MARK: - Generate PDF from messages
    static func generatePDF(
        messages: [ChatMessage],
        title: String
    ) -> Data? {
        
        let pageWidth: CGFloat = 595.2   // A4 width in points
        let pageHeight: CGFloat = 841.8  // A4 height in points
        let margin: CGFloat = 40
        let contentWidth = pageWidth - (margin * 2)
        
        // PDF renderer
        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(
                x: 0, y: 0,
                width: pageWidth,
                height: pageHeight
            )
        )
        
        let data = pdfRenderer.pdfData { context in
            
            context.beginPage()
            
            var currentY: CGFloat = margin
            
            // MARK: - Draw header
            currentY = drawHeader(
                title: title,
                date: Date(),
                pageWidth: pageWidth,
                margin: margin,
                startY: currentY
            )
            
            currentY += 20
            
            // Draw divider line
            drawDivider(
                pageWidth: pageWidth,
                margin: margin,
                y: currentY
            )
            
            currentY += 20
            
            // MARK: - Draw messages
            for message in messages {
                
                // Skip empty messages
                guard !message.text.isEmpty else { continue }
                
                // Check if we need a new page
                let estimatedHeight = estimateMessageHeight(
                    text: message.text,
                    contentWidth: contentWidth
                )
                
                if currentY + estimatedHeight > pageHeight - margin {
                    context.beginPage()
                    currentY = margin
                }
                
                currentY = drawMessage(
                    message: message,
                    startY: currentY,
                    margin: margin,
                    contentWidth: contentWidth,
                    pageWidth: pageWidth,
                    context: context,
                    pageHeight: pageHeight
                )
                
                currentY += 12
            }
            
            // MARK: - Draw footer
            drawFooter(
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                margin: margin
            )
        }
        
        return data
    }
    
    // MARK: - Draw header
    @discardableResult
    private static func drawHeader(
        title: String,
        date: Date,
        pageWidth: CGFloat,
        margin: CGFloat,
        startY: CGFloat
    ) -> CGFloat {
        
        var y = startY
        
        // App name
        let appNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.systemBlue
        ]
        "AIChat — AI Assistant".draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: appNameAttributes
        )
        
        y += 20
        
        // Conversation title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        title.draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: titleAttributes
        )
        
        y += 32
        
        // Date
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let dateString = formatter.string(from: date)
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        dateString.draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: dateAttributes
        )
        
        return y + 20
    }
    
    // MARK: - Draw single message
    @discardableResult
    private static func drawMessage(
        message: ChatMessage,
        startY: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        pageWidth: CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageHeight: CGFloat
    ) -> CGFloat {
        
        var y = startY
        let isUser = message.role == .user
        let bubbleMargin: CGFloat = 12
        let bubblePadding: CGFloat = 10
        
        // Clean markdown for PDF
        let cleanText = cleanMarkdownForPDF(message.text)
        
        // Role label
        let roleText = isUser ? "You" : "AI Assistant"
        let roleColor = isUser ? UIColor.systemBlue : UIColor.systemPurple
        
        let roleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: roleColor
        ]
        
        roleText.draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: roleAttributes
        )
        
        y += 16
        
        // Message text
        let textFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let textColor = isUser
            ? UIColor.white
            : UIColor.label
        
        let bubbleWidth = contentWidth * 0.82
        let textWidth = bubbleWidth - (bubblePadding * 2)
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor
        ]
        
        let textRect = CGRect(
            x: 0, y: 0,
            width: textWidth,
            height: CGFloat.greatestFiniteMagnitude
        )
        
        let textBounds = (cleanText as NSString).boundingRect(
            with: textRect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: textAttributes,
            context: nil
        )
        
        let bubbleHeight = textBounds.height + (bubblePadding * 2)
        
        // Position bubble
        let bubbleX = isUser
            ? (pageWidth - margin - bubbleWidth)
            : margin
        
        // Check if bubble fits on current page
        if y + bubbleHeight > pageHeight - margin - 40 {
            context.beginPage()
            y = margin
        }
        
        let bubbleRect = CGRect(
            x: bubbleX,
            y: y,
            width: bubbleWidth,
            height: bubbleHeight
        )
        
        // Draw bubble background
        let bubblePath = UIBezierPath(
            roundedRect: bubbleRect,
            cornerRadius: 12
        )
        
        if isUser {
            UIColor.systemBlue.setFill()
        } else {
            UIColor.systemGray6.setFill()
        }
        bubblePath.fill()
        
        // Draw text inside bubble
        let textDrawRect = CGRect(
            x: bubbleX + bubblePadding,
            y: y + bubblePadding,
            width: textWidth,
            height: textBounds.height
        )
        
        cleanText.draw(
            with: textDrawRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: textAttributes,
            context: nil
        )
        
        return y + bubbleHeight + bubbleMargin
    }
    
    // MARK: - Draw divider
    private static func drawDivider(
        pageWidth: CGFloat,
        margin: CGFloat,
        y: CGFloat
    ) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.systemGray4.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    // MARK: - Draw footer
    private static func drawFooter(
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        margin: CGFloat
    ) {
        let footerY = pageHeight - margin
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let footerText = "Exported from AIChat App"
        let textSize = (footerText as NSString).size(
            withAttributes: footerAttributes
        )
        footerText.draw(
            at: CGPoint(
                x: (pageWidth - textSize.width) / 2,
                y: footerY
            ),
            withAttributes: footerAttributes
        )
    }
    
    // MARK: - Estimate message height
    private static func estimateMessageHeight(
        text: String,
        contentWidth: CGFloat
    ) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12)
        let textWidth = contentWidth * 0.82 - 20
        let cleanText = cleanMarkdownForPDF(text)
        
        let bounds = (cleanText as NSString).boundingRect(
            with: CGSize(
                width: textWidth,
                height: CGFloat.greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return bounds.height + 50
    }
    
    // MARK: - Clean markdown for PDF
    private static func cleanMarkdownForPDF(
        _ text: String
    ) -> String {
        var result = text
        let replacements = [
            "**", "__", "*", "_",
            "## ", "### ", "# ",
            "```", "`",
            "---", ">>>"
        ]
        for pattern in replacements {
            result = result.replacingOccurrences(
                of: pattern,
                with: ""
            )
        }
        return result.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}
