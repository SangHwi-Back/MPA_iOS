// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
package com.example.mpa_android.model

/** "기록 내보내기" file formats. Photos are never included. */
enum class JournalExportFormat(val fileExtension: String, val mimeType: String) {
    MARKDOWN("md", "text/markdown"),
    JSON("json", "application/json"),
}

/** Builds the export file: date, title, body and keywords of each entry, oldest first. */
object JournalExporter {

    fun content(journals: List<Journal>, format: JournalExportFormat): String {
        val sorted = journals.sortedBy { it.day }
        return when (format) {
            JournalExportFormat.MARKDOWN -> markdown(sorted)
            JournalExportFormat.JSON -> json(sorted)
        }
    }

    private fun markdown(journals: List<Journal>): String = journals.joinToString("\n\n---\n\n") { journal ->
        buildList {
            add("## ${journal.day}")
            if (journal.title.isNotEmpty()) add("### ${journal.title}")
            add("")
            add(journal.body)
            val keywords = journal.visibleKeywords.map { it.name }
            if (keywords.isNotEmpty()) {
                add("")
                add("키워드: " + keywords.joinToString(" ") { "#$it" })
            }
        }.joinToString("\n")
    }

    private fun json(journals: List<Journal>): String {
        if (journals.isEmpty()) return "[]"
        return journals.joinToString(",\n", prefix = "[\n", postfix = "\n]") { journal ->
            val keywords = journal.visibleKeywords.joinToString(", ") { quote(it.name) }
            """  {
    "body" : ${quote(journal.body)},
    "date" : ${quote(journal.day.toString())},
    "keywords" : [$keywords],
    "title" : ${quote(journal.title)}
  }"""
        }
    }

    private fun quote(text: String): String = buildString {
        append('"')
        for (c in text) {
            when (c) {
                '"' -> append("\\\"")
                '\\' -> append("\\\\")
                '\n' -> append("\\n")
                '\r' -> append("\\r")
                '\t' -> append("\\t")
                else -> if (c < ' ') append("\\u%04x".format(c.code)) else append(c)
            }
        }
        append('"')
    }
}
