package com.example.mpa_android.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [JournalEntity::class, JournalPhotoEntity::class, JournalKeywordEntity::class],
    version = 1,
)
abstract class MPADatabase : RoomDatabase() {
    abstract fun journalDao(): JournalDao
}
