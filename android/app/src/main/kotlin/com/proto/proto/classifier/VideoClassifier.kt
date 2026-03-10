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
        val lowerChannel = channelName.lowercase()

        if (allowlist.any { lowerChannel.contains(it) || it.contains(lowerChannel) }) {
            return ClassificationResult(ContentType.EDUCATIONAL, "allowlist")
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
