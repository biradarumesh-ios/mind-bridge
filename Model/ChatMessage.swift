//
//  ChatMessage.swift
//  AIChat
//
//  Created by Apple on 5/11/26.
//

import Foundation
import UIKit

enum MessageRole {
    case user
    case assistant
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    var text: String
    var image: UIImage? = nil
}
