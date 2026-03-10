package com.proto.proto.classifier

enum class ContentType { EDUCATIONAL, NON_EDUCATIONAL, SHORTS }

data class ClassificationResult(val type: ContentType, val reason: String)

class VideoClassifier {
    private var allowlist: List<String> = emptyList()
    private var keywords: List<String> = emptyList()

    fun configure(allowlist: List<String>, keywords: List<String>) {
        this.allowlist = allowlist.map { it.lowercase().trim() }
        this.keywords = keywords.map { it.lowercase().trim() }
    }

    fun classify(title: String, channelName: String = ""): ClassificationResult {
        val lowerTitle = title.lowercase()
        val lowerChannel = channelName.lowercase().trim()

        // Guard: only check allowlist when channel name is actually known.
        // An empty lowerChannel would make `it.contains("")` true for every entry
        // (every string contains the empty string), classifying ALL content as educational.
        if (lowerChannel.isNotEmpty()) {
            if (allowlist.any { entry ->
                lowerChannel == entry ||
                lowerChannel.contains(entry) ||
                entry.contains(lowerChannel)
            }) {
                return ClassificationResult(ContentType.EDUCATIONAL, "allowlist")
            }
        }

        if (keywords.any { lowerTitle.contains(it) }) {
            return ClassificationResult(ContentType.EDUCATIONAL, "keyword")
        }
        return ClassificationResult(ContentType.NON_EDUCATIONAL, "default")
    }

    fun isShorts(nodeDescription: String?): Boolean {
        return nodeDescription?.lowercase()?.let {
            it.contains("shorts") || it.contains("short video")
        } ?: false
    }
}
