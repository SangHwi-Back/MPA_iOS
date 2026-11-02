package com.example.mpa_android.ui.view

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.mpa_android.R
import com.example.mpa_android.ui.theme.MPAColor

@Composable
fun SettingsHomeView() {
    var biometricLock by remember { mutableStateOf(true) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
    ) {
        // Title
        Text(
            text = "설정",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )

        Spacer(modifier = Modifier.height(32.dp))

        // ─── AI Section ───
        SettingsSectionHeader("AI")
        Spacer(modifier = Modifier.height(12.dp))

        SettingsRow(
            iconRes = R.drawable.ic_sparkle,
            title = "AI 연결",
            subtitle = "기기 내장 AI (Gemini Nano)",
            onClick = { /* navigate to AI connection view */ },
        )

        Spacer(modifier = Modifier.height(32.dp))

        // ─── 개인정보 Section ───
        SettingsSectionHeader("개인정보")
        Spacer(modifier = Modifier.height(12.dp))

        // Biometric lock with toggle
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { biometricLock = !biometricLock }
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_settings_lock),
                contentDescription = null,
                tint = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.size(24.dp),
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "지문·얼굴로 잠금",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = MPAColor.TEXT_PRIMARY.color(),
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = "앱을 열 때마다 확인",
                    style = MaterialTheme.typography.bodySmall,
                    color = MPAColor.TEXT_SECONDARY.color(),
                )
            }
            Switch(
                checked = biometricLock,
                onCheckedChange = { biometricLock = it },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.White,
                    checkedTrackColor = MPAColor.BRAND_PRIMARY.color(),
                    uncheckedThumbColor = Color.White,
                    uncheckedTrackColor = MPAColor.SUNKEN.color(),
                ),
            )
        }

        // Data storage info
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { /* navigate to info */ }
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_settings_data),
                contentDescription = null,
                tint = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.size(24.dp),
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                text = "데이터는 어디에 저장되나요?",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // ─── 기록 Section ───
        SettingsSectionHeader("기록")
        Spacer(modifier = Modifier.height(12.dp))

        SettingsRow(
            iconRes = R.drawable.ic_settings_reminder,
            title = "매일 쓰기 알림",
            subtitle = "오후 9:30",
            onClick = { /* navigate to reminder settings */ },
        )

        SettingsRow(
            iconRes = R.drawable.ic_settings_export,
            title = "기록 내보내기",
            subtitle = "텍스트 또는 JSON",
            onClick = { /* navigate to export */ },
        )

        Spacer(modifier = Modifier.height(32.dp))

        // ─── 도움말 Section ───
        SettingsSectionHeader("도움말")
        Spacer(modifier = Modifier.height(12.dp))

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { /* navigate to help */ }
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_settings_help),
                contentDescription = null,
                tint = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.size(24.dp),
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                text = "도움이 필요할 때",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "AI가 만든 초안과 요약은 참고적인 정보이나 의료 조언을 대신하지 않아요.",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_TERTIARY.color(),
            textAlign = TextAlign.Start,
        )
    }
}

// ─── Helper Composables ───

@Composable
private fun SettingsSectionHeader(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelMedium,
        fontWeight = FontWeight.SemiBold,
        color = MPAColor.BRAND_PRIMARY.color(),
        modifier = modifier,
    )
}

@Composable
private fun SettingsRow(
    iconRes: Int,
    title: String,
    subtitle: String? = null,
    onClick: () -> Unit = {},
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(iconRes),
            contentDescription = null,
            tint = MPAColor.TEXT_PRIMARY.color(),
            modifier = Modifier.size(24.dp),
        )
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            if (subtitle != null) {
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MPAColor.TEXT_SECONDARY.color(),
                )
            }
        }
    }
}