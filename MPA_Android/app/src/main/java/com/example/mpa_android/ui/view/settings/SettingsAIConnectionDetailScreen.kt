// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
package com.example.mpa_android.ui.view.settings

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.mpa_android.R
import com.example.mpa_android.model.AIConnectionState
import com.example.mpa_android.model.AIKeyConnection
import com.example.mpa_android.model.AIProvider
import com.example.mpa_android.model.keyConnection
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.viewmodel.SettingsUiState
import com.example.mpa_android.viewmodel.SettingsViewModel
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val ScreenInset = 16.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsAIConnectionDetailScreen(
    viewModel: SettingsViewModel,
    onBack: () -> Unit,
) {
    val state by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
            .verticalScroll(rememberScrollState())
            .padding(bottom = 32.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp)
                .padding(start = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_arrow_back),
                    contentDescription = "뒤로",
                    tint = MPAColor.TEXT_PRIMARY.color(),
                )
            }
            Spacer(Modifier.width(4.dp))
            Text(text = "AI 연결", fontSize = 24.sp, color = MPAColor.TEXT_PRIMARY.color())
        }
        Spacer(Modifier.height(4.dp))

        StatusCard(state.aiConnection)
        Spacer(Modifier.height(20.dp))

        if (state.showsKeyInput) {
            KeyInputSection(state, viewModel)
        }
        val connection = state.aiConnection.keyConnection
        if (connection != null && !state.isEditingKey) {
            ConnectionInfoSection(state, connection, viewModel)
        }
        if (state.aiConnection is AIConnectionState.DeviceAI) {
            SettingsSectionHeader("고급: 내 API 키 사용")
        }
    }

    if (state.isConsentPresented) {
        ModalBottomSheet(
            onDismissRequest = viewModel::cancelConsent,
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = MPAColor.CONTAINER.color(),
        ) {
            ConsentSheetContent(
                provider = state.selectedProvider,
                modifier = Modifier.fillMaxHeight(0.82f),
                onAgree = viewModel::agreeToConsent,
                onCancel = viewModel::cancelConsent,
            )
        }
    }

    if (state.isDisconnectConfirmPresented) {
        AlertDialog(
            onDismissRequest = viewModel::dismissDisconnect,
            containerColor = MPAColor.CONTAINER.color(),
            title = { Text("연결을 해제할까요?") },
            text = { Text("AI 기능이 꺼지고 일기 앱으로 사용돼요") },
            confirmButton = {
                TextButton(onClick = viewModel::disconnect) {
                    Text("연결 해제", color = MPAColor.DANGER.color())
                }
            },
            dismissButton = {
                TextButton(onClick = viewModel::dismissDisconnect) {
                    Text("취소", color = MPAColor.BRAND_PRIMARY.color())
                }
            },
        )
    }
}

// ─── Status card ───

@Composable
private fun StatusCard(state: AIConnectionState) {
    when (state) {
        is AIConnectionState.NotConnected -> StatusCardBody(
            isWarning = true,
            title = "연결 안 됨",
            detail = state.reason.message,
            caption = "일기 쓰기는 그대로 사용할 수 있어요.",
        )
        is AIConnectionState.DeviceAI -> StatusCardBody(
            isWarning = false,
            title = if (state.hasStandbyKey) "기기 내장 AI 사용 중 · 내 키는 대기 중" else "기기 내장 AI 사용 중",
            detail = "Gemini Nano로 기기 안에서 분석해요",
            caption = null,
        )
        is AIConnectionState.Connected -> {
            val name = state.connection.provider.displayName
            StatusCardBody(
                isWarning = false,
                title = "$name API (내 키) 사용 중",
                detail = "AI 카드에는 “✦ $name (내 API 키)”로 표시돼요.",
                caption = "연결 테스트 성공 · ${relativeTime(state.connection.lastTestedAtMillis)}",
            )
        }
        is AIConnectionState.KeyError -> StatusCardBody(
            isWarning = true,
            title = "키를 확인해 주세요",
            detail = "키가 만료되었거나 한도를 초과했을 수 있어요.",
            caption = "일기 쓰기는 그대로 사용할 수 있어요.",
        )
    }
}

@Composable
private fun StatusCardBody(
    isWarning: Boolean,
    title: String,
    detail: String,
    caption: String?,
) {
    val contentColor =
        if (isWarning) MPAColor.TEXT_PRIMARY.color() else MPAColor.BRAND_ON_CONTAINER.color()
    val captionColor =
        if (isWarning) MPAColor.TEXT_SECONDARY.color() else MPAColor.BRAND_ON_CONTAINER.color()

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = ScreenInset)
            .clip(RoundedCornerShape(24.dp))
            .background(if (isWarning) MPAColor.CONTAINER.color() else MPAColor.BRAND_CONTAINER.color())
            .padding(18.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(
                if (isWarning) R.drawable.ic_alert_dialog else R.drawable.ic_status_connected_outline,
            ),
            contentDescription = null,
            tint = if (isWarning) MPAColor.WARNING_TEXT.color() else Color.Unspecified,
            modifier = Modifier.size(24.dp),
        )
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = title, fontSize = 17.sp, fontWeight = FontWeight.Bold, color = contentColor)
            Text(text = detail, fontSize = 15.sp, lineHeight = 22.sp, color = contentColor)
            if (caption != null) {
                Text(text = caption, fontSize = 14.sp, color = captionColor)
            }
        }
    }
}

// ─── Key input ───

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun KeyInputSection(state: SettingsUiState, viewModel: SettingsViewModel) {
    val uriHandler = LocalUriHandler.current

    SettingsSectionHeader("내 API 키로 연결")
    Spacer(Modifier.height(4.dp))

    SingleChoiceSegmentedButtonRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = ScreenInset),
    ) {
        AIProvider.entries.forEachIndexed { index, provider ->
            SegmentedButton(
                selected = state.selectedProvider == provider,
                onClick = { viewModel.selectProvider(provider) },
                enabled = !state.isTesting,
                shape = SegmentedButtonDefaults.itemShape(index = index, count = AIProvider.entries.size),
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = MPAColor.BRAND_CONTAINER.color(),
                    activeContentColor = MPAColor.BRAND_ON_CONTAINER.color(),
                    inactiveContainerColor = Color.Transparent,
                    inactiveContentColor = MPAColor.TEXT_PRIMARY.color(),
                ),
                label = {
                    Text(
                        text = provider.displayName,
                        fontWeight = if (state.selectedProvider == provider) FontWeight.Bold else FontWeight.Normal,
                    )
                },
            )
        }
    }
    Spacer(Modifier.height(12.dp))

    KeyField(state, viewModel)
    Spacer(Modifier.height(8.dp))

    Row(
        modifier = Modifier
            .clickable { uriHandler.openUri(state.selectedProvider.keyIssueUrl) }
            .heightIn(min = 48.dp)
            .padding(horizontal = SettingsGutter),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(
            text = "${state.selectedProvider.displayName} API 키 발급 방법",
            fontSize = 15.sp,
            fontWeight = FontWeight.Bold,
            color = MPAColor.BRAND_PRIMARY.color(),
        )
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_north_east),
            contentDescription = null,
            tint = MPAColor.BRAND_PRIMARY.color(),
            modifier = Modifier.size(16.dp),
        )
    }
    Spacer(Modifier.height(8.dp))

    Button(
        onClick = viewModel::startConnectionTest,
        enabled = state.canTestConnection,
        colors = ButtonDefaults.buttonColors(
            containerColor = MPAColor.BRAND_PRIMARY.color(),
            contentColor = MPAColor.BRAND_ON_PRIMARY.color(),
            disabledContainerColor = if (state.isTesting) MPAColor.BRAND_PRIMARY.color() else MPAColor.HAIRLINE.color(),
            disabledContentColor = if (state.isTesting) MPAColor.BRAND_ON_PRIMARY.color() else MPAColor.TEXT_TERTIARY.color(),
        ),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = ScreenInset)
            .height(48.dp),
    ) {
        if (state.isTesting) {
            CircularProgressIndicator(
                color = MPAColor.BRAND_ON_PRIMARY.color(),
                strokeWidth = 2.dp,
                modifier = Modifier.size(18.dp),
            )
            Spacer(Modifier.width(8.dp))
            Text("확인 중…", fontWeight = FontWeight.Bold)
        } else {
            Text("연결 테스트", fontWeight = FontWeight.Bold)
        }
    }

    if (state.isEditingKey) {
        TextButton(
            onClick = viewModel::cancelKeyChange,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = ScreenInset),
        ) {
            Text("취소", color = MPAColor.BRAND_PRIMARY.color())
        }
    }

    SettingsFootnote(
        "키는 이 기기의 Android 키 저장소에만 저장되고, 개발자 서버를 거치지 않아요. 요금은 입력한 키의 계정에 부과돼요.",
    )
}

@Composable
private fun KeyField(state: SettingsUiState, viewModel: SettingsViewModel) {
    val clipboard = LocalClipboardManager.current
    var isKeyVisible by rememberSaveable { mutableStateOf(false) }
    val errorMessage = when {
        state.hasKeyFormatError -> "키 형식을 확인해 주세요"
        else -> state.testFailure?.message
    }

    OutlinedTextField(
        value = state.apiKeyInput,
        onValueChange = viewModel::updateApiKey,
        label = { Text("API 키") },
        singleLine = true,
        isError = errorMessage != null,
        visualTransformation = if (isKeyVisible) VisualTransformation.None else PasswordVisualTransformation(),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrectEnabled = false),
        supportingText = {
            Text(errorMessage ?: "${state.selectedProvider.keyPrefix}로 시작하는 키")
        },
        trailingIcon = {
            Row {
                IconButton(onClick = { isKeyVisible = !isKeyVisible }) {
                    Icon(
                        imageVector = ImageVector.vectorResource(R.drawable.ic_visibility),
                        contentDescription = if (isKeyVisible) "키 가리기" else "키 보기",
                        tint = Color.Unspecified,
                    )
                }
                IconButton(onClick = {
                    clipboard.getText()?.text?.let { viewModel.updateApiKey(it.trim()) }
                }) {
                    Icon(
                        imageVector = ImageVector.vectorResource(R.drawable.ic_paste),
                        contentDescription = "붙여넣기",
                        tint = Color.Unspecified,
                    )
                }
            }
        },
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = MPAColor.BRAND_PRIMARY.color(),
            unfocusedBorderColor = if (state.apiKeyInput.isEmpty()) MPAColor.TEXT_TERTIARY.color() else MPAColor.BRAND_PRIMARY.color(),
            focusedLabelColor = MPAColor.BRAND_PRIMARY.color(),
            unfocusedLabelColor = MPAColor.BRAND_PRIMARY.color(),
            cursorColor = MPAColor.BRAND_PRIMARY.color(),
            focusedSupportingTextColor = MPAColor.TEXT_SECONDARY.color(),
            unfocusedSupportingTextColor = MPAColor.TEXT_SECONDARY.color(),
            errorBorderColor = MPAColor.DANGER.color(),
            errorLabelColor = MPAColor.DANGER.color(),
            errorSupportingTextColor = MPAColor.DANGER.color(),
            errorCursorColor = MPAColor.DANGER.color(),
        ),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = ScreenInset),
    )
}

// ─── Connected ───

@Composable
private fun ConnectionInfoSection(
    state: SettingsUiState,
    connection: AIKeyConnection,
    viewModel: SettingsViewModel,
) {
    SettingsSectionHeader("연결 정보")

    InfoRow(label = "제공자", value = connection.provider.displayName)
    InfoRow(label = "API 키", value = connection.maskedKey, valueIsMonospace = true) {
        TextButton(onClick = viewModel::beginKeyChange) {
            Text("변경", fontWeight = FontWeight.Bold, color = MPAColor.BRAND_PRIMARY.color())
        }
    }
    InfoRow(label = "외부 전송 동의", value = formattedDate(connection.consentGrantedAtMillis))
    Spacer(Modifier.height(16.dp))

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = ScreenInset),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        OutlinedButton(
            onClick = viewModel::retestConnection,
            enabled = !state.isRetesting,
            border = BorderStroke(1.dp, MPAColor.TEXT_TERTIARY.color()),
            modifier = Modifier
                .weight(1f)
                .height(48.dp),
        ) {
            if (state.isRetesting) {
                CircularProgressIndicator(strokeWidth = 2.dp, modifier = Modifier.size(18.dp))
            } else {
                Text("다시 테스트", fontWeight = FontWeight.Bold, color = MPAColor.BRAND_PRIMARY.color())
            }
        }
        OutlinedButton(
            onClick = viewModel::requestDisconnect,
            border = BorderStroke(1.dp, MPAColor.DANGER.color()),
            modifier = Modifier
                .weight(1f)
                .height(48.dp),
        ) {
            Text("연결 해제", fontWeight = FontWeight.Bold, color = MPAColor.DANGER.color())
        }
    }

    state.testFailure?.let { failure ->
        Text(
            text = failure.message,
            fontSize = 13.sp,
            color = MPAColor.DANGER.color(),
            modifier = Modifier.padding(horizontal = SettingsGutter, vertical = 4.dp),
        )
    }
    SettingsFootnote("연결을 해제하면 키가 Android 키 저장소에서 지워지고 외부 전송 동의도 철회돼요. 일기는 그대로 남아요.")
}

@Composable
private fun InfoRow(
    label: String,
    value: String,
    valueIsMonospace: Boolean = false,
    trailing: @Composable () -> Unit = {},
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 64.dp)
            .padding(horizontal = SettingsGutter),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = label, fontSize = 16.sp, color = MPAColor.TEXT_PRIMARY.color())
            Text(
                text = value,
                fontSize = 14.sp,
                fontFamily = if (valueIsMonospace) FontFamily.Monospace else null,
                color = MPAColor.TEXT_SECONDARY.color(),
            )
        }
        trailing()
    }
}

@Composable
private fun SettingsFootnote(text: String) {
    Text(
        text = text,
        fontSize = 13.sp,
        lineHeight = 19.sp,
        color = MPAColor.TEXT_SECONDARY.color(),
        modifier = Modifier.padding(horizontal = SettingsGutter, vertical = 12.dp),
    )
}

// ─── Consent sheet ───

@Composable
private fun ConsentSheetContent(
    provider: AIProvider,
    modifier: Modifier = Modifier,
    onAgree: () -> Unit,
    onCancel: () -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(bottom = 24.dp),
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_cloud_upload),
                contentDescription = null,
                tint = MPAColor.BRAND_PRIMARY.color(),
                modifier = Modifier.size(28.dp),
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "일기 내용이 ${provider.companyName} 서버로 전송돼요",
                fontFamily = FontFamily.Serif,
                fontWeight = FontWeight.SemiBold,
                fontSize = 22.sp,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = "AI 분석을 위해 일기 내용이 선택한 제공자(${provider.companyName}) 서버로 전송됩니다. 요금과 데이터 처리는 입력한 키의 계정 정책을 따릅니다.",
                fontSize = 15.sp,
                lineHeight = 23.sp,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            ConsentDivider(top = 16.dp, bottom = 14.dp)
            ConsentRow(isSent = true) {
                append("가능하면 기기에서 줄인 ")
                withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append("요약·키워드") }
                append("만 보내요")
            }
            ConsentRow(isSent = true) { append("조언에 꼭 필요할 때만 본문 일부를 보내요") }
            ConsentRow(isSent = false) { append("사진과 사진 캡션은 보내지 않아요") }
            ConsentRow(isSent = false) { append("개발자 서버는 거치지 않아요") }
            ConsentDivider(top = 6.dp, bottom = 12.dp)
            Text(
                text = "동의는 설정 › AI 연결의 ‘연결 해제’로 언제든 철회할 수 있어요.",
                fontSize = 13.sp,
                color = MPAColor.TEXT_SECONDARY.color(),
            )
        }

        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(
                onClick = onCancel,
                border = BorderStroke(1.dp, MPAColor.TEXT_TERTIARY.color()),
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp),
            ) {
                Text("취소", fontWeight = FontWeight.Bold, color = MPAColor.BRAND_PRIMARY.color())
            }
            Button(
                onClick = onAgree,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MPAColor.BRAND_PRIMARY.color(),
                    contentColor = MPAColor.BRAND_ON_PRIMARY.color(),
                ),
                modifier = Modifier
                    .weight(1.9f)
                    .height(48.dp),
            ) {
                Text("동의하고 연결", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun ConsentDivider(top: androidx.compose.ui.unit.Dp, bottom: androidx.compose.ui.unit.Dp) {
    HorizontalDivider(
        color = MPAColor.HAIRLINE.color(),
        modifier = Modifier.padding(top = top, bottom = bottom),
    )
}

@Composable
private fun ConsentRow(
    isSent: Boolean,
    text: androidx.compose.ui.text.AnnotatedString.Builder.() -> Unit,
) {
    Row(
        modifier = Modifier.padding(bottom = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(
                if (isSent) R.drawable.ic_consent_send else R.drawable.ic_consent_not_send,
            ),
            contentDescription = if (isSent) "보내는 것" else "보내지 않는 것",
            tint = Color.Unspecified,
            modifier = Modifier.size(20.dp),
        )
        Text(
            text = buildAnnotatedString(text),
            fontSize = 15.sp,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
    }
}

// ─── Helpers ───

private fun relativeTime(millis: Long): String {
    val minutes = (System.currentTimeMillis() - millis) / 60_000
    return when {
        minutes < 1 -> "방금"
        minutes < 60 -> "${minutes}분 전"
        minutes < 1_440 -> "${minutes / 60}시간 전"
        else -> "${minutes / 1_440}일 전"
    }
}

private fun formattedDate(millis: Long): String =
    DateTimeFormatter.ofPattern("yyyy년 M월 d일", Locale.KOREAN)
        .format(Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()))

// ─── Preview ───

private const val PREVIEW_KEY = "AIzaSyD00000000"

@Preview(name = "aiConnectionDetail", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun AIConnectionDetailPreview() {
    val viewModel = remember {
        previewSettingsViewModel(PreviewNotConnected).apply { updateApiKey(PREVIEW_KEY) }
    }
    SettingsAIConnectionDetailScreen(viewModel = viewModel, onBack = {})
}

@Preview(name = "beforeConfirm", showBackground = true, widthDp = 412, heightDp = 750)
@Composable
private fun BeforeConfirmPreview() {
    Column(Modifier.background(MPAColor.CONTAINER.color())) {
        ConsentSheetContent(
            provider = AIProvider.GEMINI,
            modifier = Modifier
                .fillMaxHeight()
                .padding(top = 32.dp),
            onAgree = {},
            onCancel = {},
        )
    }
}

@Preview(name = "afterConfirm", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun AfterConfirmPreview() {
    val viewModel = remember {
        previewSettingsViewModel(AIConnectionState.Connected(PreviewKeyConnection))
    }
    SettingsAIConnectionDetailScreen(viewModel = viewModel, onBack = {})
}
