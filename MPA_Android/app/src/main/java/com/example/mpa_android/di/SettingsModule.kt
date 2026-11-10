package com.example.mpa_android.di

import com.example.mpa_android.model.AIConnectionState
import com.example.mpa_android.model.AIDeviceStateProvider
import com.example.mpa_android.model.AIKeyTester
import com.example.mpa_android.model.AIUnavailableReason
import com.example.mpa_android.model.StubAIKeyTester
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
@Module
@InstallIn(SingletonComponent::class)
object SettingsModule {

    @Provides
    fun provideAIKeyTester(): AIKeyTester = StubAIKeyTester()

    /** Gemini Nano is not integrated yet, so the device reports no on-device AI. */
    @Provides
    fun provideAIDeviceStateProvider(): AIDeviceStateProvider =
        AIDeviceStateProvider { AIConnectionState.NotConnected(AIUnavailableReason.UNSUPPORTED) }
}
