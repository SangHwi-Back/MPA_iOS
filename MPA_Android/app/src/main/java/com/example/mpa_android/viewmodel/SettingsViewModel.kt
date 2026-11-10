// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
package com.example.mpa_android.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mpa_android.model.AIConnectionState
import com.example.mpa_android.model.AIConsentRecord
import com.example.mpa_android.model.AIDeviceStateProvider
import com.example.mpa_android.model.AIKeyConnection
import com.example.mpa_android.model.AIKeyTestFailure
import com.example.mpa_android.model.AIKeyTester
import com.example.mpa_android.model.AIProvider
import com.example.mpa_android.model.keyConnection
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SettingsUiState(
    val aiConnection: AIConnectionState,
    val selectedProvider: AIProvider = AIProvider.GEMINI,
    val apiKeyInput: String = "",
    val isEditingKey: Boolean = false,
    val isConsentPresented: Boolean = false,
    val isDisconnectConfirmPresented: Boolean = false,
    val isTesting: Boolean = false,
    val isRetesting: Boolean = false,
    val testFailure: AIKeyTestFailure? = null,
    val consent: AIConsentRecord? = null,
    val biometricLockEnabled: Boolean = true,
    val dailyReminderTime: String = "오후 9:30",
    val appVersion: String = "1.0.0",
) {
    val trimmedKey: String get() = apiKeyInput.trim()

    val hasKeyFormatError: Boolean
        get() = trimmedKey.isNotEmpty() && !trimmedKey.startsWith(selectedProvider.keyPrefix)

    val canTestConnection: Boolean
        get() = trimmedKey.isNotEmpty() && !hasKeyFormatError && !isTesting

    val showsKeyInput: Boolean
        get() = when (aiConnection) {
            is AIConnectionState.NotConnected -> true
            is AIConnectionState.Connected, is AIConnectionState.KeyError -> isEditingKey
            is AIConnectionState.DeviceAI -> false
        }
}

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val keyTester: AIKeyTester,
    private val deviceState: AIDeviceStateProvider,
) : ViewModel() {

    internal var now: () -> Long = System::currentTimeMillis

    private val _uiState = MutableStateFlow(SettingsUiState(aiConnection = deviceState.current()))
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    // Held in memory only until Keystore storage is added.
    private var connectedKey: String? = null

    fun selectProvider(provider: AIProvider) {
        if (_uiState.value.selectedProvider == provider) return
        _uiState.update { it.copy(selectedProvider = provider, apiKeyInput = "", testFailure = null) }
    }

    fun updateApiKey(key: String) {
        _uiState.update { it.copy(apiKeyInput = key, testFailure = null) }
    }

    /** Asks for consent first unless it was already given for the selected provider. */
    fun startConnectionTest() {
        val state = _uiState.value
        if (!state.canTestConnection) return
        if (state.consent?.provider == state.selectedProvider) {
            runKeyTest()
        } else {
            _uiState.update { it.copy(isConsentPresented = true) }
        }
    }

    fun agreeToConsent() {
        _uiState.update {
            it.copy(
                consent = AIConsentRecord(it.selectedProvider, now()),
                isConsentPresented = false,
            )
        }
        runKeyTest()
    }

    fun cancelConsent() {
        _uiState.update { it.copy(isConsentPresented = false) }
    }

    fun beginKeyChange() {
        _uiState.update {
            it.copy(
                selectedProvider = it.aiConnection.keyConnection?.provider ?: it.selectedProvider,
                apiKeyInput = "",
                isEditingKey = true,
                testFailure = null,
            )
        }
    }

    fun cancelKeyChange() {
        _uiState.update { it.copy(apiKeyInput = "", isEditingKey = false, testFailure = null) }
    }

    fun retestConnection() {
        val state = _uiState.value
        val connection = state.aiConnection.keyConnection ?: return
        val key = connectedKey ?: return
        if (state.isRetesting) return

        _uiState.update { it.copy(isRetesting = true, testFailure = null) }
        viewModelScope.launch {
            val failure = keyTester.test(key, connection.provider)
            _uiState.update {
                when (failure) {
                    null -> it.copy(
                        isRetesting = false,
                        aiConnection = AIConnectionState.Connected(connection.copy(lastTestedAtMillis = now())),
                    )
                    AIKeyTestFailure.OFFLINE -> it.copy(isRetesting = false, testFailure = failure)
                    AIKeyTestFailure.INVALID_KEY, AIKeyTestFailure.QUOTA_EXCEEDED -> it.copy(
                        isRetesting = false,
                        aiConnection = AIConnectionState.KeyError(connection),
                    )
                }
            }
        }
    }

    fun requestDisconnect() {
        _uiState.update { it.copy(isDisconnectConfirmPresented = true) }
    }

    fun dismissDisconnect() {
        _uiState.update { it.copy(isDisconnectConfirmPresented = false) }
    }

    fun disconnect() {
        connectedKey = null
        _uiState.update {
            it.copy(
                aiConnection = deviceState.current(),
                consent = null,
                apiKeyInput = "",
                isEditingKey = false,
                isDisconnectConfirmPresented = false,
                testFailure = null,
            )
        }
    }

    fun setBiometricLock(enabled: Boolean) {
        _uiState.update { it.copy(biometricLockEnabled = enabled) }
    }

    private fun runKeyTest() {
        val state = _uiState.value
        val key = state.trimmedKey
        val provider = state.selectedProvider
        val grantedAt = state.consent?.grantedAtMillis ?: return

        _uiState.update { it.copy(isTesting = true, testFailure = null) }
        viewModelScope.launch {
            val failure = keyTester.test(key, provider)
            if (failure != null) {
                _uiState.update { it.copy(isTesting = false, testFailure = failure) }
                return@launch
            }
            connectedKey = key
            _uiState.update {
                it.copy(
                    isTesting = false,
                    aiConnection = AIConnectionState.Connected(
                        AIKeyConnection(provider, maskedKey(key), now(), grantedAt),
                    ),
                    apiKeyInput = "",
                    isEditingKey = false,
                )
            }
        }
    }

    companion object {
        fun maskedKey(key: String): String =
            if (key.length <= 7) "••••••" else "${key.take(4)}••••••${key.takeLast(3)}"
    }
}
