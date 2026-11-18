// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.mpa_android.ui.view.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.mpa_android.R
import com.example.mpa_android.ui.TestTags
import com.example.mpa_android.ui.theme.MPAColor

/**
 * "매일 쓰기 알림" dialog: on/off switch plus an M3 TimePicker. The keyboard button switches to
 * typed input. 확인 applies the choice, 취소 or tapping outside discards it.
 */
@Composable
fun SettingsAlertDailyWriteDatePickerScreen(
    enabled: Boolean,
    hour: Int,
    minute: Int,
    onConfirm: (enabled: Boolean, hour: Int, minute: Int) -> Unit,
    onDismiss: () -> Unit,
) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        DailyWriteDatePickerContent(enabled, hour, minute, onConfirm, onDismiss)
    }
}

@Composable
private fun DailyWriteDatePickerContent(
    enabled: Boolean,
    hour: Int,
    minute: Int,
    onConfirm: (enabled: Boolean, hour: Int, minute: Int) -> Unit,
    onDismiss: () -> Unit,
) {
    var isOn by remember { mutableStateOf(enabled) }
    var isTyping by remember { mutableStateOf(false) }
    val timeState = rememberTimePickerState(initialHour = hour, initialMinute = minute, is24Hour = false)
    val colors = TimePickerDefaults.colors(
        clockDialColor = MPAColor.HAIRLINE.color(),
        selectorColor = MPAColor.BRAND_PRIMARY.color(),
        timeSelectorSelectedContainerColor = MPAColor.BRAND_CONTAINER.color(),
        timeSelectorSelectedContentColor = MPAColor.BRAND_ON_CONTAINER.color(),
        timeSelectorUnselectedContainerColor = MPAColor.HAIRLINE.color(),
        periodSelectorSelectedContainerColor = MPAColor.WARNING.color().copy(alpha = 0.15f),
        periodSelectorSelectedContentColor = MPAColor.WARNING_TEXT.color(),
    )

    Surface(
        shape = RoundedCornerShape(28.dp),
        color = MPAColor.CONTAINER.color(),
        // Dialogs are separate windows, so the app root's testTagsAsResourceId does not reach them.
        modifier = Modifier
            .testTag(TestTags.AlertDailyWriteDatePicker.SCREEN)
            .semantics { testTagsAsResourceId = true }
            .padding(horizontal = 42.dp)
            .widthIn(max = 328.dp),
    ) {
        Column(modifier = Modifier.padding(start = 24.dp, end = 24.dp, top = 24.dp, bottom = 12.dp)) {
            Text(text = "알림 시간 선택", fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
            Spacer(Modifier.height(16.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "알림 받기",
                    fontSize = 18.sp,
                    color = MPAColor.TEXT_PRIMARY.color(),
                    modifier = Modifier.weight(1f),
                )
                Switch(
                    checked = isOn,
                    onCheckedChange = { isOn = it },
                    modifier = Modifier.testTag(TestTags.AlertDailyWriteDatePicker.TOGGLE),
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = MPAColor.BRAND_ON_PRIMARY.color(),
                        checkedTrackColor = MPAColor.BRAND_PRIMARY.color(),
                        uncheckedThumbColor = MPAColor.TEXT_SECONDARY.color(),
                        uncheckedTrackColor = MPAColor.SUNKEN.color(),
                    ),
                )
            }

            if (isOn) {
                Spacer(Modifier.height(20.dp))
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    if (isTyping) {
                        TimeInput(state = timeState, modifier = Modifier.testTag(TestTags.AlertDailyWriteDatePicker.TIME_PICKER), colors = colors)
                    } else {
                        TimePicker(state = timeState, modifier = Modifier.testTag(TestTags.AlertDailyWriteDatePicker.TIME_PICKER), colors = colors)
                    }
                }
            }

            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                if (isOn) {
                    IconButton(
                        onClick = { isTyping = !isTyping },
                        modifier = Modifier.testTag(TestTags.AlertDailyWriteDatePicker.INPUT_MODE_TOGGLE),
                    ) {
                        Icon(
                            imageVector = ImageVector.vectorResource(if (isTyping) R.drawable.ic_schedule else R.drawable.ic_keyboard),
                            contentDescription = if (isTyping) "시계로 고르기" else "직접 입력",
                            tint = MPAColor.TEXT_SECONDARY.color(),
                        )
                    }
                }
                Spacer(Modifier.weight(1f))
                TextButton(onClick = onDismiss, modifier = Modifier.testTag(TestTags.AlertDailyWriteDatePicker.CANCEL)) {
                    Text("취소", color = MPAColor.BRAND_PRIMARY.color())
                }
                TextButton(
                    onClick = { onConfirm(isOn, timeState.hour, timeState.minute) },
                    modifier = Modifier.testTag(TestTags.AlertDailyWriteDatePicker.CONFIRM),
                ) {
                    Text("확인", color = MPAColor.BRAND_PRIMARY.color())
                }
            }
        }
    }
}

@Preview(name = "alertDailyWriteDatePicker", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun AlertDailyWriteDatePickerPreview() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        DailyWriteDatePickerContent(enabled = true, hour = 21, minute = 30, onConfirm = { _, _, _ -> }, onDismiss = {})
    }
}
