package com.example.mpa_android.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface JournalDao {

    @Transaction
    @Query("SELECT * FROM journals ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<JournalWithRelations>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertJournal(journal: JournalEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPhotos(photos: List<JournalPhotoEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertKeywords(keywords: List<JournalKeywordEntity>)

    @Query("DELETE FROM journal_photos WHERE journalId = :journalId")
    suspend fun deletePhotos(journalId: String)

    @Query("DELETE FROM journal_keywords WHERE journalId = :journalId")
    suspend fun deleteKeywords(journalId: String)

    @Query("DELETE FROM journals WHERE id = :journalId")
    suspend fun deleteJournal(journalId: String)

    @Transaction
    suspend fun upsert(journal: JournalEntity, photos: List<JournalPhotoEntity>, keywords: List<JournalKeywordEntity>) {
        insertJournal(journal)
        deletePhotos(journal.id)
        deleteKeywords(journal.id)
        if (photos.isNotEmpty()) insertPhotos(photos)
        if (keywords.isNotEmpty()) insertKeywords(keywords)
    }
}
