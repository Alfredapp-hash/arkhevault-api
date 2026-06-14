import Foundation

enum TypingDocumentMode: String, CaseIterable, Codable, Identifiable {
    case essay
    case email
    case notes
    case code

    var id: String { rawValue }

    var title: String {
        switch self {
        case .essay: return "Essay"
        case .email: return "Email"
        case .notes: return "Notes"
        case .code: return "Code"
        }
    }

    var icon: String {
        switch self {
        case .essay: return "text.book.closed"
        case .email: return "envelope"
        case .notes: return "note.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var description: String {
        switch self {
        case .essay: return "Long-form writing with deep thought and paragraph arcs"
        case .email: return "Shorter pauses, quicker bursts, moderate errors"
        case .notes: return "Fast, informal, minimal planning pauses"
        case .code: return "Steady bursts, symbol slowdown, few thinking breaks"
        }
    }

    var pauseMultiplier: Double {
        switch self {
        case .essay: return 1.0
        case .email: return 0.72
        case .notes: return 0.48
        case .code: return 0.38
        }
    }

    var velocityMultiplier: Double {
        switch self {
        case .essay: return 1.0
        case .email: return 1.08
        case .notes: return 1.18
        case .code: return 1.12
        }
    }

    var errorMultiplier: Double {
        switch self {
        case .essay: return 1.0
        case .email: return 0.85
        case .notes: return 0.7
        case .code: return 0.55
        }
    }

    var revisionProbability: Double {
        switch self {
        case .essay: return 0.012
        case .email: return 0.008
        case .notes: return 0.004
        case .code: return 0.002
        }
    }
}
