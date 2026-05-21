//
//  PDFPreviewView.swift
//  AIChat
//
//  Created by Apple on 5/21/26.
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    
    let pdfData: Data
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            PDFKitView(pdfData: pdfData)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Chat Export")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            
                            // Save to files
                            Button {
                                savePDFToFiles()
                            } label: {
                                Image(systemName: "arrow.down.doc")
                                    .foregroundColor(.blue)
                            }
                            
                            // Share
                            Button {
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(items: [pdfData])
                }
        }
    }
    
    // MARK: - Save to Files app
    func savePDFToFiles() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AIChat_Conversation.pdf")
        
        do {
            try pdfData.write(to: tempURL)
            let shareSheet = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared
                .connectedScenes
                .first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(
                    shareSheet,
                    animated: true
                )
            }
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }
}

// MARK: - PDFKit view wrapper
struct PDFKitView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(
        _ uiView: PDFView,
        context: Context
    ) {}
}
