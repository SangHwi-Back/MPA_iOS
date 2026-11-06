package com.example.mpa_android.data

import com.android.identity.util.UUID
import com.example.mpa_android.data.local.JournalDao
import com.example.mpa_android.model.Journal
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

interface JournalRepository {
    val journals: Flow<List<Journal>>
    suspend fun save(journal: Journal)
    suspend fun delete(id: UUID)
}

class JournalRepositoryImpl @Inject constructor(
    private val dao: JournalDao,
) : JournalRepository {

    override val journals: Flow<List<Journal>> =
        dao.observeAll().map { rows -> rows.map { it.toDomain() } }

    override suspend fun save(journal: Journal) {
        val (entity, photos, keywords) = journal.toEntities()
        dao.upsert(entity, photos, keywords)
    }

    override suspend fun delete(id: UUID) {
        dao.deleteJournal(id.toString())
    }
}
