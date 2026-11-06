package com.example.mpa_android.data.local

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation

@Entity(tableName = "journals")
data class JournalEntity(
    @PrimaryKey val id: String,
    val day: String,
    val createdAt: String,
    val editedAt: String?,
    val title: String,
    val body: String,
    val prompt: String?,
    val analysisStateType: String,
    val analyzedAt: String?,
    val aiCommentText: String?,
    val aiCommentEngine: String?,
    val aiCommentGeneratedAt: String?,
    val aiCommentSourceIds: String?,
    val aiCommentFeedback: String?,
)

@Entity(
    tableName = "journal_photos",
    foreignKeys = [
        ForeignKey(
            entity = JournalEntity::class,
            parentColumns = ["id"],
            childColumns = ["journalId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("journalId")],
)
data class JournalPhotoEntity(
    @PrimaryKey val id: String,
    val journalId: String,
    val fileName: String,
    val caption: String,
    val position: Int,
)

@Entity(
    tableName = "journal_keywords",
    foreignKeys = [
        ForeignKey(
            entity = JournalEntity::class,
            parentColumns = ["id"],
            childColumns = ["journalId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("journalId")],
)
data class JournalKeywordEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val journalId: String,
    val name: String,
    val source: String,
    val influence: Double,
    val isExcluded: Boolean,
)

data class JournalWithRelations(
    @Embedded val journal: JournalEntity,
    @Relation(parentColumn = "id", entityColumn = "journalId")
    val photos: List<JournalPhotoEntity>,
    @Relation(parentColumn = "id", entityColumn = "journalId")
    val keywords: List<JournalKeywordEntity>,
)
