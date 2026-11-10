@file:OptIn(ExperimentalCoroutinesApi::class)

package com.example.mpa_android.viewmodel

import com.example.mpa_android.model.AIConnectionState
import com.example.mpa_android.model.AIKeyTestFailure
import com.example.mpa_android.model.AIProvider
import com.example.mpa_android.model.AIUnavailableReason
import com.example.mpa_android.model.keyConnection
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class SettingsViewModelTest {

    private val geminiKey = "AIzaSyABCDEFG3f9"
    private val deviceDefault = AIConnectionState.NotConnected(AIUnavailableReason.UNSUPPORTED)
    private val dispatcher = StandardTestDispatcher()
    private var testResult: AIKeyTestFailure? = null
    private lateinit var viewModel: SettingsViewModel

    private val state get() = viewModel.uiState.value

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        viewModel = SettingsViewModel({ _, _ -> testResult }, { deviceDefault })
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun TestScope.connect() {
        viewModel.updateApiKey(geminiKey)
        viewModel.startConnectionTest()
        viewModel.agreeToConsent()
        advanceUntilIdle()
    }

    @Test
    fun maskedKeyKeepsFourPrefixAndThreeSuffix() {
        assertEquals("AIza••••••3f9", SettingsViewModel.maskedKey(geminiKey))
    }

    @Test
    fun keyFormatValidation() {
        viewModel.updateApiKey("sk-abc")
        assertTrue(state.hasKeyFormatError)
        assertFalse(state.canTestConnection)

        viewModel.updateApiKey("  AIza123456  ")
        assertEquals("AIza123456", state.trimmedKey)
        assertTrue(state.canTestConnection)

        viewModel.updateApiKey("")
        assertFalse(state.hasKeyFormatError)
        assertFalse(state.canTestConnection)
    }

    @Test
    fun firstConnectionAsksForConsent() {
        viewModel.updateApiKey(geminiKey)
        viewModel.startConnectionTest()

        assertTrue(state.isConsentPresented)
        assertEquals(deviceDefault, state.aiConnection)
    }

    @Test
    fun cancelConsentKeepsDiaryMode() {
        viewModel.updateApiKey(geminiKey)
        viewModel.startConnectionTest()
        viewModel.cancelConsent()

        assertFalse(state.isConsentPresented)
        assertNull(state.consent)
        assertEquals(deviceDefault, state.aiConnection)
    }

    @Test
    fun agreeConnectsAndClearsInput() = runTest(dispatcher) {
        connect()

        assertEquals("AIza••••••3f9", state.aiConnection.keyConnection?.maskedKey)
        assertEquals(AIProvider.GEMINI, state.aiConnection.keyConnection?.provider)
        assertEquals("", state.apiKeyInput)
        assertFalse(state.isConsentPresented)
    }

    @Test
    fun failedFirstTestStaysNotConnected() = runTest(dispatcher) {
        testResult = AIKeyTestFailure.INVALID_KEY
        connect()

        assertEquals(AIKeyTestFailure.INVALID_KEY, state.testFailure)
        assertEquals(deviceDefault, state.aiConnection)
    }

    @Test
    fun keyChangeWithSameProviderSkipsConsent() = runTest(dispatcher) {
        connect()
        viewModel.beginKeyChange()
        viewModel.updateApiKey("AIzaNewKey000999")
        viewModel.startConnectionTest()
        advanceUntilIdle()

        assertFalse(state.isConsentPresented)
        assertEquals("AIza••••••999", state.aiConnection.keyConnection?.maskedKey)
        assertFalse(state.isEditingKey)
    }

    @Test
    fun changingProviderClearsKeyAndRequiresConsent() = runTest(dispatcher) {
        connect()
        viewModel.beginKeyChange()
        viewModel.updateApiKey(geminiKey)
        viewModel.selectProvider(AIProvider.OPENAI)
        assertEquals("", state.apiKeyInput)

        viewModel.updateApiKey("sk-abcdefghij")
        viewModel.startConnectionTest()
        assertTrue(state.isConsentPresented)
    }

    @Test
    fun retestQuotaFailureBecomesKeyError() = runTest(dispatcher) {
        connect()
        testResult = AIKeyTestFailure.QUOTA_EXCEEDED
        viewModel.retestConnection()
        advanceUntilIdle()

        assertTrue(state.aiConnection is AIConnectionState.KeyError)
    }

    @Test
    fun retestOfflineKeepsConnection() = runTest(dispatcher) {
        connect()
        testResult = AIKeyTestFailure.OFFLINE
        viewModel.retestConnection()
        advanceUntilIdle()

        assertTrue(state.aiConnection is AIConnectionState.Connected)
        assertEquals(AIKeyTestFailure.OFFLINE, state.testFailure)
    }

    @Test
    fun disconnectClearsConsentAndRestoresDeviceState() = runTest(dispatcher) {
        connect()
        viewModel.disconnect()

        assertNull(state.consent)
        assertEquals(deviceDefault, state.aiConnection)
    }
}
