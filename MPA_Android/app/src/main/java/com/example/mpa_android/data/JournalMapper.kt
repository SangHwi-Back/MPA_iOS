@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.data

import com.android.identity.util.UUID
import com.example.mpa_android.data.local.JournalEntity
import com.example.mpa_android.data.local.JournalKeywordEntity
import com.example.mpa_android.data.local.JournalPhotoEntity
import com.example.mpa_android.data.local.JournalWithRelations
import com.example.mpa_android.model.AIEngine
import com.example.mpa_android.model.AIFeedback
import com.example.mpa_android.model.AIText
import com.example.mpa_android.model.AnalysisState
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalKeyword
import com.example.mpa_android.model.JournalPhoto
import com.example.mpa_android.model.KeywordSource
import java.time.LocalDate
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

fun Journal.toEntities(): JournalWithRelations {
    val journal = JournalEntity(
        id = id.toString(),
        day = day.toString(),
        createdAt = createdAt.toString(),
        editedAt = editedAt?.toString(),
        title = title,
        body = body,
        prompt = prompt,
        analysisStateType = analysisState.toTypeString(),
        analyzedAt = (analysisState as? AnalysisState.Analyzed)?.at?.toString(),
        aiCommentText = aiComment?.text,
        aiCommentEngine = aiComment?.engine?.name,
        aiCommentGeneratedAt = aiComment?.generatedAt?.toString(),
        aiCommentSourceIds = aiComment?.sourceJournalIds?.takeIf { it.isNotEmpty() }?.joinToString(",") { it.toString() },
        aiCommentFeedback = aiComment?.feedback?.name,
    )
    val photos = this.photos.mapIndexed { index, photo ->
        JournalPhotoEntity(
            id = photo.id.toString(),
            journalId = journal.id,
            fileName = photo.fileName,
            caption = photo.caption,
            position = index,
        )
    }
    val keywords = this.keywords.map { keyword ->
        JournalKeywordEntity(
            journalId = journal.id,
            name = keyword.name,
            source = keyword.source.name,
            influence = keyword.influence,
            isExcluded = keyword.isExcluded,
        )
    }
    return JournalWithRelations(journal, photos, keywords)
}

fun JournalWithRelations.toDomain(): Journal {
    val aiComment = if (journal.aiCommentText != null && journal.aiCommentEngine != null && journal.aiCommentGeneratedAt != null) {
        AIText(
            text = journal.aiCommentText,
            engine = AIEngine.valueOf(journal.aiCommentEngine),
            generatedAt = Instant.parse(journal.aiCommentGeneratedAt),
            sourceJournalIds = journal.aiCommentSourceIds
                ?.split(",")
                ?.filter { it.isNotBlank() }
                ?.map { UUID.fromString(it) }
                ?: emptyList(),
            feedback = journal.aiCommentFeedback?.let { AIFeedback.valueOf(it) },
        )
    } else {
        null
    }
    return Journal(
        id = UUID.fromString(journal.id),
        day = LocalDate.parse(journal.day),
        createdAt = Instant.parse(journal.createdAt),
        editedAt = journal.editedAt?.let { Instant.parse(it) },
        title = journal.title,
        body = journal.body,
        prompt = journal.prompt,
        photos = photos.sortedBy { it.position }.map {
            JournalPhoto(id = UUID.fromString(it.id), fileName = it.fileName, caption = it.caption)
        },
        keywords = keywords.map {
            JournalKeyword(
                name = it.name,
                source = KeywordSource.valueOf(it.source),
                influence = it.influence,
                isExcluded = it.isExcluded,
            )
        },
        analysisState = journal.toAnalysisState(),
        aiComment = aiComment,
    )
}

private fun AnalysisState.toTypeString(): String = when (this) {
    is AnalysisState.NotAnalyzed -> "NOT_ANALYZED"
    is AnalysisState.Analyzing -> "ANALYZING"
    is AnalysisState.Analyzed -> "ANALYZED"
    is AnalysisState.Failed -> "FAILED"
    is AnalysisState.Unavailable -> "UNAVAILABLE"
}

private fun JournalEntity.toAnalysisState(): AnalysisState = when (analysisStateType) {
    "ANALYZING" -> AnalysisState.Analyzing
    "ANALYZED" -> AnalysisState.Analyzed(Instant.parse(analyzedAt!!))
    "FAILED" -> AnalysisState.Failed
    "UNAVAILABLE" -> AnalysisState.Unavailable
    else -> AnalysisState.NotAnalyzed
}
