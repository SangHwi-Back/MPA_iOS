// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
package com.example.mpa_android.ui.view.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.mpa_android.R
import com.example.mpa_android.model.AIConnectionState
import com.example.mpa_android.model.AIKeyConnection
import com.example.mpa_android.model.AIUnavailableReason
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.viewmodel.SettingsUiState
import com.example.mpa_android.viewmodel.SettingsViewModel

internal val SettingsGutter = 20.dp

@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onOpenAIConnection: () -> Unit,
) {
    val state by viewModel.uiState.collectAsState()

    SettingsContent(
        state = state,
        onOpenAIConnection = onOpenAIConnection,
        onBiometricLockChange = viewModel::setBiometricLock,
    )
}

@Composable
private fun SettingsContent(
    state: SettingsUiState,
    onOpenAIConnection: () -> Unit,
    onBiometricLockChange: (Boolean) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
            .verticalScroll(rememberScrollState())
            .padding(top = 36.dp, bottom = 32.dp),
    ) {
        Text(
            text = "설정",
            fontFamily = FontFamily.Serif,
            fontWeight = FontWeight.SemiBold,
            fontSize = 30.sp,
            color = MPAColor.TEXT_PRIMARY.color(),
            modifier = Modifier
                .padding(horizontal = SettingsGutter)
                .semantics { heading() },
        )
        Spacer(Modifier.height(16.dp))

        SettingsSectionHeader("AI")
        SettingsRow(
            iconRes = R.drawable.ic_settings_ai,
            title = "AI 연결",
            subtitle = connectionValue(state.aiConnection),
            onClick = onOpenAIConnection,
        )

        SettingsSectionGap()
        SettingsSectionHeader("개인정보")
        SettingsRow(
            iconRes = R.drawable.ic_settings_lock,
            title = "지문·얼굴로 잠금",
            subtitle = "앱을 열 때마다 확인",
            onClick = { onBiometricLockChange(!state.biometricLockEnabled) },
        ) {
            BiometricSwitch(state.biometricLockEnabled, onBiometricLockChange)
        }
        SettingsRow(iconRes = R.drawable.ic_settings_data, title = "데이터는 어디에 저장되나요?")

        SettingsSectionGap()
        SettingsSectionHeader("기록")
        SettingsRow(
            iconRes = R.drawable.ic_settings_reminder,
            title = "매일 쓰기 알림",
            subtitle = state.dailyReminderTime,
        )
        SettingsRow(
            iconRes = R.drawable.ic_settings_export,
            title = "기록 내보내기",
            subtitle = "텍스트 또는 JSON",
        )

        SettingsSectionGap()
        SettingsSectionHeader("도움말")
        SettingsRow(iconRes = R.drawable.ic_settings_help, title = "도움이 필요할 때")
        SettingsRow(
            iconRes = R.drawable.ic_settings_about,
            title = "앱 정보",
            subtitle = state.appVersion,
        )

        Text(
            text = "AI가 만든 조언과 요약은 전문적인 상담이나 의료 조언을 대신하지 않아요.",
            fontSize = 13.sp,
            lineHeight = 19.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
            modifier = Modifier.padding(start = 60.dp, end = SettingsGutter, top = 12.dp),
        )
    }
}

private fun connectionValue(state: AIConnectionState): String = when (state) {
    is AIConnectionState.NotConnected -> "연결 안 됨"
    is AIConnectionState.DeviceAI -> "기기 내장 AI (Gemini Nano)"
    is AIConnectionState.Connected -> "${state.connection.provider.displayName} (내 키)"
    is AIConnectionState.KeyError -> "${state.connection.provider.displayName} (내 키)"
}

@Composable
private fun SettingsSectionGap() {
    Spacer(Modifier.height(16.dp))
}

@Composable
internal fun SettingsSectionHeader(text: String) {
    Text(
        text = text,
        fontSize = 14.sp,
        fontWeight = FontWeight.Bold,
        color = MPAColor.BRAND_PRIMARY.color(),
        modifier = Modifier
            .padding(horizontal = SettingsGutter)
            .padding(top = 8.dp, bottom = 4.dp)
            .semantics { heading() },
    )
}

@Composable
private fun SettingsRow(
    iconRes: Int,
    title: String,
    subtitle: String? = null,
    onClick: () -> Unit = {},
    trailing: @Composable () -> Unit = {},
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 64.dp)
            .clickable(onClick = onClick)
            .padding(horizontal = SettingsGutter),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(iconRes),
            contentDescription = null,
            tint = Color.Unspecified,
            modifier = Modifier.size(24.dp),
        )
        Spacer(Modifier.width(16.dp))
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Text(text = title, fontSize = 16.sp, color = MPAColor.TEXT_PRIMARY.color())
            if (subtitle != null) {
                Text(text = subtitle, fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
            }
        }
        trailing()
    }
}

@Composable
private fun BiometricSwitch(checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Switch(
        checked = checked,
        onCheckedChange = onCheckedChange,
        thumbContent = if (checked) {
            {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_check),
                    contentDescription = null,
                    tint = MPAColor.BRAND_PRIMARY.color(),
                    modifier = Modifier.size(SwitchDefaults.IconSize),
                )
            }
        } else {
            null
        },
        colors = SwitchDefaults.colors(
            checkedThumbColor = MPAColor.BRAND_ON_PRIMARY.color(),
            checkedTrackColor = MPAColor.BRAND_PRIMARY.color(),
            checkedBorderColor = MPAColor.BRAND_PRIMARY.color(),
            uncheckedThumbColor = MPAColor.TEXT_SECONDARY.color(),
            uncheckedTrackColor = MPAColor.SUNKEN.color(),
            uncheckedBorderColor = MPAColor.TEXT_TERTIARY.color(),
        ),
    )
}

// ─── Preview ───

internal fun previewSettingsViewModel(state: AIConnectionState) =
    SettingsViewModel({ _, _ -> null }, { state })

internal val PreviewNotConnected =
    AIConnectionState.NotConnected(AIUnavailableReason.UNSUPPORTED)

// Consent time is 2026-10-30 noon in KST, so the date reads the same in nearby zones.
internal val PreviewKeyConnection = AIKeyConnection(
    provider = com.example.mpa_android.model.AIProvider.GEMINI,
    maskedKey = "AIza••••••3f9",
    lastTestedAtMillis = System.currentTimeMillis(),
    consentGrantedAtMillis = 1_793_329_200_000L,
)

@Preview(name = "settings", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun SettingsPreview() {
    val viewModel = remember { previewSettingsViewModel(AIConnectionState.DeviceAI(false)) }
    SettingsScreen(viewModel = viewModel, onOpenAIConnection = {})
}
