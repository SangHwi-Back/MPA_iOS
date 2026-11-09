package com.example.mpa_android.ui.view.journal

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.mpa_android.R
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalKeyword
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.viewmodel.JournalViewModel
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.Month

private val DAY_ORDER = listOf(
    DayOfWeek.SUNDAY,
    DayOfWeek.MONDAY,
    DayOfWeek.TUESDAY,
    DayOfWeek.WEDNESDAY,
    DayOfWeek.THURSDAY,
    DayOfWeek.FRIDAY,
    DayOfWeek.SATURDAY,
)

private val DAY_LABELS = listOf("일", "월", "화", "수", "목", "금", "토")

private val KOREAN_WEEKDAYS = listOf(
    "일요일",
    "월요일",
    "화요일",
    "수요일",
    "목요일",
    "금요일",
    "토요일",
)

private val TODAY = LocalDate.now()

private fun isLeapYear(year: Int): Boolean =
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0

private fun daysInMonth(year: Int, month: Int): Int = when (month) {
    1, 3, 5, 7, 8, 10, 12 -> 31
    4, 6, 9, 11 -> 30
    2 -> if (isLeapYear(year)) 29 else 28
    else -> 30
}

private fun DayOfWeek.koreanShortName(): String =
    DAY_LABELS[DAY_ORDER.indexOf(this)]

private fun DayOfWeek.koreanFullName(): String =
    KOREAN_WEEKDAYS[DAY_ORDER.indexOf(this)]

@Composable
fun JournalHomeView(viewModel: JournalViewModel = hiltViewModel()) {
    val journals = viewModel.journals.collectAsState()

    var isCalendar by remember { mutableStateOf(false) }
    var viewYear by remember { mutableIntStateOf(TODAY.year) }
    var viewMonth by remember { mutableStateOf(TODAY.month) }
    var selectedDay by remember { mutableIntStateOf(TODAY.dayOfMonth) }

    val monthStart = LocalDate.of(viewYear, viewMonth, 1)
    val nextMonthStart = LocalDate.of(
        if (viewMonth.value == 12) viewYear + 1 else viewYear,
        if (viewMonth.value == 12) 1 else viewMonth.value + 1,
        1,
    )
    val monthEntries = journals.value
        .filter { journal ->
            journal.day in monthStart..<nextMonthStart
        }
        .sortedByDescending { it.day }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color()),
    ) {
        JournalSearchBar(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 16.dp, top = 12.dp),
        )

        JournalToggle(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp, bottom = 4.dp),
            selected = isCalendar,
            onToggle = { isCalendar = it },
        )

        if (isCalendar) {
            JournalCalendar(
                viewYear = viewYear,
                viewMonth = viewMonth.value,
                selectedDay = selectedDay,
                entries = monthEntries,
                onPreviousMonth = {
                    if (viewMonth.value == 1) {
                        viewYear -= 1
                        viewMonth = Month.of(12)
                    } else {
                        viewMonth = Month.of(viewMonth.value - 1)
                    }
                },
                onNextMonth = {
                    if (viewMonth.value == 12) {
                        viewYear += 1
                        viewMonth = Month.of(1)
                    } else {
                        viewMonth = Month.of(viewMonth.value + 1)
                    }
                },
                onSelectDay = { day -> selectedDay = day },
            )
        } else if (journals.value.isEmpty()) {
            JournalEmptyState(
                modifier = Modifier.fillMaxSize(),
            )
        } else {
            JournalEntryList(
                entries = monthEntries,
                viewYear = viewYear,
                viewMonth = viewMonth.value,
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

@Composable
private fun JournalSearchBar(modifier: Modifier = Modifier) {
    var query by remember { mutableStateOf("") }

    TextField(
        value = query,
        onValueChange = { query = it },
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MPAColor.SUNKEN.color()),
        placeholder = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            ) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_search),
                    contentDescription = null,
                    tint = MPAColor.TEXT_TERTIARY.color(),
                    modifier = Modifier.size(18.dp),
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "기록 검색",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MPAColor.TEXT_SECONDARY.color(),
                )
            }
        },
        singleLine = true,
        shape = RoundedCornerShape(12.dp),
        colors = TextFieldDefaults.colors(),
        textStyle = MaterialTheme.typography.bodyMedium,
    )
}

@Composable
private fun JournalToggle(
    selected: Boolean,
    onToggle: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(50.dp)),
    ) {
        Row(modifier = Modifier.fillMaxWidth().height(44.dp)) {
            ToggleHalf(
                text = "리스트",
                selected = !selected,
                onClick = { onToggle(false) },
                modifier = Modifier.weight(1f),
            )
            ToggleHalf(
                text = "캘린더",
                selected = selected,
                onClick = { onToggle(true) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun ToggleHalf(
    text: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(50.dp))
            .background(if (selected) MPAColor.BRAND_CONTAINER.color() else Color.Transparent)
            .clickable(onClick = onClick)
            .height(44.dp)
            .fillMaxWidth(),
        contentAlignment = Alignment.Center,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (selected) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_check),
                    contentDescription = null,
                    tint = MPAColor.BRAND_ON_CONTAINER.color(),
                    modifier = Modifier.size(16.dp),
                )
                Spacer(modifier = Modifier.width(4.dp))
            }
            Text(
                text = text,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium,
                color = if (selected) MPAColor.BRAND_ON_CONTAINER.color() else MPAColor.TEXT_PRIMARY.color(),
            )
        }
    }
}

@Composable
private fun JournalMonthHeader(
    year: Int,
    month: Int,
    count: Int,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "${year}년 ${month}월",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = "${count}건",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
    }
}

@Composable
private fun JournalEntryList(
    entries: List<Journal>,
    viewYear: Int,
    viewMonth: Int,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
            .verticalScroll(rememberScrollState()),
    ) {
        JournalMonthHeader(
            year = viewYear,
            month = viewMonth,
            count = entries.size,
            modifier = Modifier.padding(start = 16.dp, top = 8.dp, bottom = 4.dp),
        )

        entries.forEachIndexed { index, entry ->
            JournalEntryRow(entry = entry)
            if (index < entries.lastIndex) {
                HorizontalDivider(
                    modifier = Modifier.padding(start = 96.dp, end = 16.dp),
                    color = MPAColor.HAIRLINE.color(),
                )
            }
        }
    }
}

@Composable
private fun JournalEntryRow(entry: Journal, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(end = 12.dp),
        ) {
            Text(
                text = entry.day.toString(),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Text(
                text = entry.day.dayOfWeek.koreanShortName(),
                style = MaterialTheme.typography.bodySmall,
                color = MPAColor.TEXT_TERTIARY.color(),
            )
        }

        Column(
            modifier = Modifier.weight(1f).padding(end = 12.dp),
        ) {
            Text(
                text = entry.displayTitle,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = entry.previewText,
                style = MaterialTheme.typography.bodyMedium,
                color = MPAColor.TEXT_SECONDARY.color(),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (entry.visibleKeywords.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    entry.visibleKeywords.take(2).forEach { keyword ->
                        KeywordChip(keyword = keyword)
                    }
                }
            }
        }

        if (entry.thumbnail != null) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(MPAColor.SUNKEN.color()),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_image_placeholder_glyph),
                    contentDescription = null,
                    tint = MPAColor.TEXT_TERTIARY.color(),
                    modifier = Modifier.size(24.dp),
                )
            }
        }
    }
}

@Composable
private fun KeywordChip(
    keyword: JournalKeyword,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(50.dp))
            .background(MPAColor.SUNKEN.color())
            .padding(horizontal = 10.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier.size(6.dp).clip(CircleShape).background(MPAColor.BRAND_PRIMARY.color()),
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = keyword.name,
            style = MaterialTheme.typography.labelSmall,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
    }
}

@Composable
private fun JournalCalendar(
    viewYear: Int,
    viewMonth: Int,
    selectedDay: Int,
    entries: List<Journal>,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    onSelectDay: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val firstOfMonth = LocalDate.of(viewYear, viewMonth, 1)
    val leading = DAY_ORDER.indexOf(firstOfMonth.dayOfWeek)
    val currentMonthDays = daysInMonth(viewYear, viewMonth)
    val prevYear = if (viewMonth == 1) viewYear - 1 else viewYear
    val prevMonthNumber = if (viewMonth == 1) 12 else viewMonth - 1
    val prevMonthDays = daysInMonth(prevYear, prevMonthNumber)
    val nextYear = if (viewMonth == 12) viewYear + 1 else viewYear
    val nextMonthNumber = if (viewMonth == 12) 1 else viewMonth + 1

    val cells = remember(viewYear, viewMonth) {
        val list = mutableListOf<Pair<LocalDate, Boolean>>()
        if (leading > 0) {
            for (d in (prevMonthDays - leading + 1)..prevMonthDays) {
                list.add(LocalDate.of(prevYear, prevMonthNumber, d) to false)
            }
        }
        for (d in 1..currentMonthDays) {
            list.add(LocalDate.of(viewYear, viewMonth, d) to true)
        }
        var padDay = 1
        while (list.size % 7 != 0) {
            list.add(LocalDate.of(nextYear, nextMonthNumber, padDay) to false)
            padDay += 1
        }
        list
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
            .verticalScroll(rememberScrollState()),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 16.dp, end = 16.dp, top = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_chevron_left),
                contentDescription = "이전 달",
                tint = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.clickable { onPreviousMonth() }.size(24.dp),
            )
            Spacer(modifier = Modifier.width(8.dp))
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.weight(1f)) {
                Text(
                    text = "${viewYear}년 ${viewMonth}월",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MPAColor.TEXT_PRIMARY.color(),
                )
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_expand_more),
                    contentDescription = "다음 달",
                    tint = MPAColor.TEXT_PRIMARY.color(),
                    modifier = Modifier.size(16.dp),
                )
            }
            Spacer(modifier = Modifier.width(8.dp))
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_chevron_right),
                contentDescription = "다음 달",
                tint = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.clickable { onNextMonth() }.size(24.dp),
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
        ) {
            DAY_LABELS.forEach { label ->
                Box(
                    modifier = Modifier.weight(1f).padding(vertical = 4.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelSmall,
                        color = MPAColor.TEXT_TERTIARY.color(),
                    )
                }
            }
        }

        cells.chunked(7).forEach { week ->
            Row(modifier = Modifier.fillMaxWidth()) {
                week.forEach { (date, isCurrentMonth) ->
                    CalendarDayCell(
                        dayOfMonth = date.dayOfMonth,
                        isCurrentMonth = isCurrentMonth,
                        hasEntry = isCurrentMonth && entries.any { entry ->
                            entry.day.compareTo(LocalDate.of(viewYear, viewMonth, date.dayOfMonth)) == 0
                        },
                        isToday = date == TODAY,
                        isSelected = isCurrentMonth && date.dayOfMonth == selectedDay,
                        onClick = { onSelectDay(date.dayOfMonth) },
                    )
                }
            }
        }

        JournalSelectedDateCard(
            viewYear = viewYear,
            viewMonth = viewMonth,
            selectedDay = selectedDay,
            entries = entries,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(top = 8.dp, bottom = 24.dp),
        )
    }
}

@Composable
private fun RowScope.CalendarDayCell(
    dayOfMonth: Int,
    isCurrentMonth: Boolean,
    hasEntry: Boolean,
    isToday: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    val contentColor =
        if (isCurrentMonth) MPAColor.TEXT_PRIMARY.color() else MPAColor.TEXT_TERTIARY.color()

    Box(
        modifier = Modifier
            .weight(1f)
            .height(48.dp)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (isToday) {
            Box(
                modifier = Modifier
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(MPAColor.BRAND_PRIMARY.color()),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = dayOfMonth.toString(),
                    color = MPAColor.BRAND_ON_PRIMARY.color(),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        } else if (isSelected) {
            Box(
                modifier = Modifier
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(MPAColor.BRAND_CONTAINER.color())
                    .border(1.dp, MPAColor.BRAND_PRIMARY.color(), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = dayOfMonth.toString(),
                    color = MPAColor.BRAND_ON_CONTAINER.color(),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        } else {
            Text(
                text = dayOfMonth.toString(),
                color = contentColor,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isCurrentMonth) FontWeight.Medium else FontWeight.Normal,
            )
        }

        if (hasEntry) {
            Box(
                modifier = Modifier
                    .size(4.dp)
                    .clip(CircleShape)
                    .background(MPAColor.BRAND_PRIMARY.color())
                    .align(Alignment.BottomCenter),
            )
        }
    }
}

@Composable
private fun JournalSelectedDateCard(
    viewYear: Int,
    viewMonth: Int,
    selectedDay: Int,
    entries: List<Journal>,
    modifier: Modifier = Modifier,
) {
    val selectedEntry = entries.firstOrNull { entry ->
        entry.day.compareTo(LocalDate.of(viewYear, viewMonth, selectedDay)) == 0
    }
    val dateLabel = "${viewMonth}월 ${selectedDay}일 ${LocalDate.of(viewYear, viewMonth, selectedDay).dayOfWeek.koreanFullName()}"
    val bodyPreview = selectedEntry?.body?.lineSequence()?.firstOrNull() ?: ""

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MPAColor.SURFACE.color())
            .padding(16.dp),
    ) {
        Text(
            text = dateLabel,
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = selectedDay.toString(),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Text(
            text = LocalDate.of(viewYear, viewMonth, selectedDay).dayOfWeek.koreanShortName(),
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_TERTIARY.color(),
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = selectedEntry?.displayTitle ?: "",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = bodyPreview,
            style = MaterialTheme.typography.bodyMedium,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
        if (selectedEntry != null && selectedEntry.visibleKeywords.isNotEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                selectedEntry.visibleKeywords.take(2).forEach { keyword ->
                    KeywordChip(keyword = keyword)
                }
            }
        }
    }
}

@Composable
private fun JournalEmptyState(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color()),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_empty_journal),
                contentDescription = null,
                modifier = Modifier.size(120.dp),
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "아직 기록이 없어요",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "첫 일기를 쓰면 여기에\n날짜별로 차곡차곡 모여요.",
                style = MaterialTheme.typography.bodySmall,
                color = MPAColor.TEXT_SECONDARY.color(),
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.height(24.dp))
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(12.dp))
                    .background(MPAColor.BRAND_CONTAINER.color())
                    .padding(horizontal = 20.dp, vertical = 14.dp)
                    .clickable { },
                contentAlignment = Alignment.Center,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = ImageVector.vectorResource(R.drawable.ic_edit),
                        contentDescription = null,
                        tint = MPAColor.BRAND_ON_CONTAINER.color(),
                        modifier = Modifier.size(18.dp),
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "✏️ 첫 일기 쓰기",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = MPAColor.BRAND_ON_CONTAINER.color(),
                    )
                }
            }
        }
    }
}

@Preview(name = "JournalHomeLight", showBackground = true)
@Composable
private fun JournalHomeViewLightPreview() {
    JournalHomeView()
}

@Preview(
    name = "JournalHomeDark",
    showBackground = true,
    uiMode = Configuration.UI_MODE_NIGHT_YES,
)
@Composable
private fun JournalHomeViewDarkPreview() {
    JournalHomeView()
}