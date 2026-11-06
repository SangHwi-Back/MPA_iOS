@file:OptIn(ExperimentalTime::class, ExperimentalMaterial3Api::class)

package com.example.mpa_android.ui.view

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.mpa_android.R
import com.example.mpa_android.model.Journal
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.viewmodel.JournalViewModel
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.*
import kotlin.time.ExperimentalTime
import kotlin.time.toJavaInstant
import java.time.Instant as JavaInstant

/**
 * 일기 작성/저장 화면. 디자인 시안(1.png = 새 일기, 2.png = 저장됨, 3.png = 날짜 선택)을 따른다.
 * 저장 전에는 "완료" 버튼으로 [JournalViewModel.addJournal]을 1회 호출해 저장하고,
 * 저장 후에는 저장 시각을 보여주는 상태로 전환된다 (저장 후 재편집은 아직 지원하지 않음).
 */
@Composable
fun JournalEditorScreen(
    onClose: () -> Unit,
    initialPrompt: String? = null,
    viewModel: JournalViewModel = hiltViewModel(),
) {
    var day by remember { mutableStateOf(LocalDate.now()) }
    var title by rememberSaveable { mutableStateOf("") }
    var body by rememberSaveable { mutableStateOf("") }
    var prompt by remember { mutableStateOf(initialPrompt) }
    var showDatePicker by remember { mutableStateOf(false) }
    var savedJournal by remember { mutableStateOf<Journal?>(null) }

    val isEmpty = title.isBlank() && body.isBlank()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color()),
    ) {
        EditorTopBar(
            savedJournal = savedJournal,
            doneEnabled = !isEmpty,
            onClose = onClose,
            onDone = {
                savedJournal = viewModel.addJournal(
                    day = day,
                    title = title,
                    body = body,
                    prompt = prompt,
                )
            },
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
        ) {
            Spacer(Modifier.height(8.dp))
            DateField(day = day, onClick = { showDatePicker = true })
            Spacer(Modifier.height(12.dp))

            prompt?.let { text ->
                PromptChip(text = text, onDismiss = { prompt = null })
                Spacer(Modifier.height(16.dp))
            }

            EditorTitleField(value = title, onValueChange = { title = it })
            EditorBodyField(value = body, onValueChange = { body = it })

            if (savedJournal != null && savedJournal?.visibleKeywords?.isNotEmpty() == true) {
                Spacer(Modifier.height(16.dp))
                KeywordsSection(keywords = savedJournal!!.visibleKeywords.map { it.name })
            }
            Spacer(Modifier.height(16.dp))
        }

        EditorBottomToolbar(
            onPhotoClick = { },
            onMicClick = { },
        )
    }

    if (showDatePicker) {
        EditorDatePickerDialog(
            initialDate = day,
            onConfirm = { picked ->
                day = picked
                showDatePicker = false
            },
            onDismiss = { showDatePicker = false },
        )
    }
}

// ── Top bar ──────────────────────────────────────────────────────────
@Composable
private fun EditorTopBar(
    savedJournal: Journal?,
    doneEnabled: Boolean,
    onClose: () -> Unit,
    onDone: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(onClick = onClose) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_close),
                contentDescription = "닫기",
                tint = MPAColor.TEXT_PRIMARY.color(),
            )
        }

        Spacer(Modifier.weight(1f))

        if (savedJournal == null) {
            Text(
                text = "완료",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = if (doneEnabled) MPAColor.BRAND_ON_PRIMARY.color() else MPAColor.TEXT_TERTIARY.color(),
                modifier = Modifier
                    .clip(RoundedCornerShape(999.dp))
                    .background(if (doneEnabled) MPAColor.BRAND_PRIMARY.color() else MPAColor.SUNKEN.color())
                    .clickable(enabled = doneEnabled, onClick = onDone)
                    .padding(horizontal = 20.dp, vertical = 10.dp),
            )
        } else {
            val savedTime = savedJournal.createdAt.toJavaInstant()
                .atZone(java.time.ZoneId.systemDefault())
                .format(DateTimeFormatter.ofPattern("a h:mm", Locale.KOREAN))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_check),
                    contentDescription = null,
                    tint = MPAColor.TEXT_SECONDARY.color(),
                    modifier = Modifier.size(16.dp),
                )
                Spacer(Modifier.width(4.dp))
                Text(
                    text = "저장됨 · $savedTime",
                    style = MaterialTheme.typography.bodySmall,
                    color = MPAColor.TEXT_SECONDARY.color(),
                )
            }
            Spacer(Modifier.width(4.dp))
            IconButton(onClick = { }) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_more_vert),
                    contentDescription = "더 보기",
                    tint = MPAColor.TEXT_PRIMARY.color(),
                )
            }
        }
    }
}

// ── Date field ───────────────────────────────────────────────────────
@Composable
private fun DateField(day: LocalDate, onClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.clickable(onClick = onClick),
    ) {
        Text(
            text = "${day.monthValue}월 ${day.dayOfMonth}일 ${day.dayOfWeek.getDisplayName(TextStyle.FULL, Locale.KOREAN)}",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.BRAND_PRIMARY.color(),
        )
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_expand_more),
            contentDescription = null,
            tint = MPAColor.BRAND_PRIMARY.color(),
            modifier = Modifier.size(18.dp),
        )
    }
}

// ── AI prompt chip ───────────────────────────────────────────────────
@Composable
private fun PromptChip(text: String, onDismiss: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MPAColor.BRAND_CONTAINER.color())
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_sparkle),
            contentDescription = null,
            tint = MPAColor.AI_ACCENT.color(),
            modifier = Modifier.size(14.dp),
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = MPAColor.BRAND_ON_CONTAINER.color(),
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(8.dp))
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_close),
            contentDescription = "질문 지우기",
            tint = MPAColor.BRAND_ON_CONTAINER.color(),
            modifier = Modifier
                .size(18.dp)
                .clickable(onClick = onDismiss),
        )
    }
}

// ── Title & body ─────────────────────────────────────────────────────
private val transparentFieldColors
    @Composable get() = TextFieldDefaults.colors(
        unfocusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
        focusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
        unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
        focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
    )

@Composable
private fun EditorTitleField(value: String, onValueChange: (String) -> Unit) {
    TextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 0.dp),
        placeholder = {
            Text(
                text = "오늘의 제목",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_TERTIARY.color(),
            )
        },
        singleLine = true,
        textStyle = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.SemiBold),
        colors = transparentFieldColors,
    )
}

@Composable
private fun EditorBodyField(value: String, onValueChange: (String) -> Unit) {
    TextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 280.dp),
        placeholder = {
            Text(
                text = "떠오르는 대로 몇 줄 적어보세요.",
                style = MaterialTheme.typography.bodyLarge,
                color = MPAColor.TEXT_TERTIARY.color(),
            )
        },
        textStyle = MaterialTheme.typography.bodyLarge,
        colors = transparentFieldColors,
    )
}

// ── Keywords (shown only once the entry has been analyzed) ────────────
@Composable
private fun KeywordsSection(keywords: List<String>) {
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_sparkle),
                contentDescription = null,
                tint = MPAColor.AI_ACCENT.color(),
                modifier = Modifier.size(14.dp),
            )
            Spacer(Modifier.width(4.dp))
            Text(
                text = "이 일기에서 발견한 키워드",
                style = MaterialTheme.typography.labelMedium,
                color = MPAColor.AI_ACCENT.color(),
            )
        }
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            keywords.forEach { name ->
                Text(
                    text = name,
                    style = MaterialTheme.typography.labelMedium,
                    color = MPAColor.TEXT_PRIMARY.color(),
                    modifier = Modifier
                        .clip(RoundedCornerShape(999.dp))
                        .background(MPAColor.SUNKEN.color())
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                )
            }
        }
    }
}

// ── Bottom toolbar ───────────────────────────────────────────────────
@Composable
private fun EditorBottomToolbar(
    onPhotoClick: () -> Unit,
    onMicClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MPAColor.CONTAINER.color())
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_image_placeholder_glyph),
            contentDescription = "사진 추가",
            tint = MPAColor.TEXT_SECONDARY.color(),
            modifier = Modifier.size(22.dp).clickable(onClick = onPhotoClick),
        )
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_mic),
            contentDescription = "음성 입력",
            tint = MPAColor.TEXT_SECONDARY.color(),
            modifier = Modifier.size(22.dp).clickable(onClick = onMicClick),
        )
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .clip(RoundedCornerShape(999.dp))
                .background(MPAColor.BRAND_CONTAINER.color())
                .padding(horizontal = 12.dp, vertical = 6.dp),
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_sparkle),
                contentDescription = null,
                tint = MPAColor.BRAND_ON_CONTAINER.color(),
                modifier = Modifier.size(14.dp),
            )
            Spacer(Modifier.width(4.dp))
            Text(
                text = "글감",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Medium,
                color = MPAColor.BRAND_ON_CONTAINER.color(),
            )
        }
    }
}

// ── Date picker dialog ───────────────────────────────────────────────
@Composable
private fun EditorDatePickerDialog(
    initialDate: LocalDate,
    onConfirm: (LocalDate) -> Unit,
    onDismiss: () -> Unit,
) {
    val state = rememberDatePickerState(
        initialSelectedDateMillis = initialDate.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
    )
    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = {
                state.selectedDateMillis?.let { millis ->
                    onConfirm(JavaInstant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate())
                } ?: onDismiss()
            }) {
                Text("확인", color = MPAColor.BRAND_PRIMARY.color())
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("취소", color = MPAColor.TEXT_SECONDARY.color())
            }
        },
        colors = DatePickerDefaults.colors(
            containerColor = MPAColor.SURFACE.color(),
            titleContentColor = MPAColor.TEXT_SECONDARY.color(),
            headlineContentColor = MPAColor.TEXT_PRIMARY.color(),
            selectedDayContainerColor = MPAColor.BRAND_PRIMARY.color(),
            selectedDayContentColor = MPAColor.BRAND_ON_PRIMARY.color(),
            todayDateBorderColor = MPAColor.BRAND_PRIMARY.color(),
            todayContentColor = MPAColor.BRAND_PRIMARY.color(),
        ),
    ) {
        DatePicker(
            state = state,
            colors = DatePickerDefaults.colors(
                containerColor = MPAColor.SURFACE.color(),
                selectedDayContainerColor = MPAColor.BRAND_PRIMARY.color(),
                selectedDayContentColor = MPAColor.BRAND_ON_PRIMARY.color(),
                todayDateBorderColor = MPAColor.BRAND_PRIMARY.color(),
                todayContentColor = MPAColor.BRAND_PRIMARY.color(),
            ),
        )
    }
}