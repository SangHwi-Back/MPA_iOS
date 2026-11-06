package com.example.mpa_android.di

import android.content.Context
import androidx.room.Room
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.data.JournalRepositoryImpl
import com.example.mpa_android.data.local.JournalDao
import com.example.mpa_android.data.local.MPADatabase
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): MPADatabase =
        Room.databaseBuilder(context, MPADatabase::class.java, "mpa.db").build()

    @Provides
    fun provideJournalDao(database: MPADatabase): JournalDao = database.journalDao()
}

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindJournalRepository(impl: JournalRepositoryImpl): JournalRepository
}
