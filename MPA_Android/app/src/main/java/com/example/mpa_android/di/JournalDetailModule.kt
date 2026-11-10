// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
package com.example.mpa_android.di

import com.example.mpa_android.model.JournalCommentGenerator
import com.example.mpa_android.model.StubJournalCommentGenerator
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
object JournalDetailModule {

    /** Gemini Nano and the API key providers are not integrated yet. */
    @Provides
    fun provideJournalCommentGenerator(): JournalCommentGenerator = StubJournalCommentGenerator()
}
