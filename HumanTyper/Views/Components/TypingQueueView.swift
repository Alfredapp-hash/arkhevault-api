import SwiftUI

struct TypingQueueView: View {
    @Binding var queue: [TypingQueueItem]
    let fullText: String
    let selection: TextSelectionState
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Queue")
                    .font(AppTheme.headlineFont())
                Spacer()
                Button("Add Selection") { addSelection() }
                    .buttonStyle(GhostActionButtonStyle())
                    .disabled(isDisabled || !selection.hasSelection)
                Button("Clear Queue") { queue.removeAll() }
                    .buttonStyle(GhostActionButtonStyle())
                    .disabled(isDisabled || queue.isEmpty)
            }

            if queue.isEmpty {
                Text("Queue multiple sections to type in order.")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textTertiary)
            } else {
                ForEach(queue) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(AppTheme.captionFont())
                            Text(item.text.prefix(60) + (item.text.count > 60 ? "…" : ""))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        Spacer()
                        Button {
                            queue.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.textTertiary)
                        .disabled(isDisabled)
                    }
                }
            }
        }
    }

    private func addSelection() {
        guard let selected = selection.selectedText(in: fullText) else { return }
        let label = "Section \(queue.count + 1) (\(selected.count) chars)"
        queue.append(TypingQueueItem(text: selected, label: label))
    }
}
