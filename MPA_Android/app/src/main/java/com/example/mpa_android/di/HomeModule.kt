// [NO AC] Spec: specs/home/SCREEN_SPEC.md
package com.example.mpa_android.di

import com.example.mpa_android.model.HomeAIGenerator
import com.example.mpa_android.model.StubHomeAIGenerator
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
object HomeModule {

    /** Gemini Nano and the API key providers are not integrated yet. */
    @Provides
    fun provideHomeAIGenerator(): HomeAIGenerator = StubHomeAIGenerator()
}
