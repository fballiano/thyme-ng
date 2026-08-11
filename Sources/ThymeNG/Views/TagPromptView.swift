import SwiftUI

/// Asks for the tag of a session that just finished.
///
/// `Skip` stores the session without a tag. The original app called that button
/// `Cancel`, but it stored the session as well, so the name was misleading.
struct TagPromptView: View {
    let duration: TimeInterval
    let onSubmit: (String) -> Void

    @State private var tag = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Session finished")
                    .font(.headline)

                Text(TimeFormatter.clock(duration))
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TextField("Tag", text: $tag)
                .textFieldStyle(.roundedBorder)
                .focused($isFieldFocused)
                .onSubmit { onSubmit(tag) }

            HStack {
                Spacer()

                Button("Skip") { onSubmit("") }
                    .keyboardShortcut(.cancelAction)

                Button("Save") { onSubmit(tag) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
        .onAppear { isFieldFocused = true }
    }
}
