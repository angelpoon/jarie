import Foundation

/// Builds prompts for daily digest generation
public enum DigestPromptBuilder {
    public static func build(captures: [CaptureSnapshot], date: Date) -> String {
        let dateStr = DateFormatters.fullDate.string(from: date)
        let captureList = captures.enumerated().map { index, capture in
            var entry = "\(index + 1). "
            if capture.type == .url, let url = capture.sourceURL {
                let title = capture.sourceTitle ?? capture.content
                entry += "[\(title)](\(url))"
            } else {
                entry += capture.content
            }
            if let domain = capture.sourceDomain {
                entry += " (from \(domain))"
            }
            let time = DateFormatters.time.string(from: capture.createdAt)
            entry += " — \(time)"
            return entry
        }.joined(separator: "\n")

        return """
        You are an AI assistant that creates concise daily digests of captured content.

        Today's date: \(dateStr)
        Number of captures: \(captures.count)

        Here are today's captures:

        \(captureList)

        Create a brief daily digest that:
        1. Groups related captures into themes
        2. Highlights key insights or patterns
        3. Notes any action items or follow-ups
        4. Uses markdown formatting
        5. Keeps the digest under 500 words

        Write the digest in a warm, helpful tone. Focus on what matters most.
        """
    }
}

/// Builds prompts for AI profile generation and rewriting
public enum ProfilePromptBuilder {
    public static func buildGeneration(
        currentProfile: String?,
        recentCaptures: [CaptureSnapshot]
    ) -> String {
        let capturesSummary = recentCaptures.prefix(50).map { capture in
            var entry = "- "
            if capture.type == .url, let title = capture.sourceTitle {
                entry += title
            } else {
                entry += String(capture.content.prefix(200))
            }
            if !capture.tags.isEmpty {
                entry += " [tags: \(capture.tags.joined(separator: ", "))]"
            }
            return entry
        }.joined(separator: "\n")

        let profileContext: String
        if let existing = currentProfile {
            profileContext = """
            Here is the current profile to update:

            \(existing)

            Update this profile incorporating the new captures below. Preserve existing insights \
            that are still relevant. Add new patterns and interests that emerge from recent captures.
            """
        } else {
            profileContext = """
            This is the first profile generation. Create a comprehensive profile from scratch \
            based on the captures below.
            """
        }

        return """
        You are an AI assistant that maintains a living profile of a person based on \
        what they capture (articles, text snippets, URLs).

        \(profileContext)

        Recent captures:

        \(capturesSummary)

        Generate a profile in markdown that includes:
        1. **Interests & Focus Areas** — What topics do they follow?
        2. **Professional Context** — What do they work on?
        3. **Tools & Technologies** — What stack/tools appear frequently?
        4. **Communication Style** — Inferred from the types of content they save
        5. **Current Projects** — What are they actively exploring?

        Keep the profile concise (2-3K tokens max). Write in third person. \
        Focus on patterns, not individual captures. This profile will be pasted into \
        AI assistants to provide instant context.
        """
    }

    public static func buildRewrite(currentProfile: String, userPrompt: String) -> String {
        return """
        You are an AI assistant. Here is a person's AI profile:

        \(currentProfile)

        The user wants this profile rewritten with the following instruction:
        "\(userPrompt)"

        Rewrite the profile accordingly. Keep it concise (2-3K tokens max). \
        Maintain the same level of detail but adapt the tone, emphasis, and structure \
        to match the user's request.
        """
    }
}
