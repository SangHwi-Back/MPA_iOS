package com.example.mpa_android.ui.view.home

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.scrollable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.mpa_android.R
import com.example.mpa_android.ui.theme.MPAColor

// ── Root ──────────────────────────────────────────────────────────────
@Composable
fun HomeView(onAddJournal: () -> Unit = {}) {
    val scrollviewState = rememberScrollState()
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
    ) {
        HeaderButtons(onAddClick = onAddJournal)
        Spacer(Modifier.height(16.dp))
        Column(
            modifier = Modifier
                .verticalScroll(scrollviewState)
                .padding(16.dp),
        ) {
            GreetingHeader()
            Spacer(Modifier.height(16.dp))
            JournalQuestionCard()
            Spacer(Modifier.height(8.dp))
            JournalReflectionCard()
            Spacer(Modifier.height(20.dp))
            MyWishSection()
            Spacer(Modifier.height(16.dp))
            NextWeeksSummaryCard()
            Spacer(Modifier.height(16.dp))
            TodayJournalPromptCard()
            Spacer(Modifier.height(16.dp))
            ThisWeekCalendarStrip(
                days = listOf(
                    WeekDayCell("월", "26", hasJournal = true),
                    WeekDayCell("화", "27", hasJournal = true),
                    WeekDayCell("수", "28"),
                    WeekDayCell("목", "29", hasJournal = true),
                    WeekDayCell("금", "30", isSelected = true),
                    WeekDayCell("토", "31", isCurrentWeek = false),
                    WeekDayCell("일", "1", isCurrentWeek = false),
                ),
                onOpenCalendar = {}
            )
            Spacer(Modifier.height(16.dp))
            RecentJournalSection(
                items = listOf(
                    RecentJournalItem(
                        "29", "목", "퇴근길 산책",
                        "한 정거장 먼저 내려서 걸었다. 바람이 차가워서 오히려 머리가 맑아졌다.",
                        hasPhoto = true
                    ),
                    RecentJournalItem(
                        "27", "화", "회의에서 말을 끊지 않기",
                        "끝까지 듣고 나니 내가 하려던 질문이 달라졌다."
                    ),
                ),
            )
            Spacer(Modifier.height(36.dp))
        }
    }
}

// ── Greeting ──────────────────────────────────────────────────────────
@Composable
private fun HeaderButtons(onAddClick: () -> Unit = {}) {
    val shadow = Shadow(
        radius = 0.15.dp,
        color = MPAColor.TEXT_PRIMARY.color().copy(alpha = 0.08f),
    )
    val modifier = Modifier
        .padding(end = 16.dp)
        .size(44.dp)
        .dropShadow(CircleShape, shadow)
    Row {
        Spacer(Modifier.weight(1f))
        IconButton(
            onClick = { },
            modifier,
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_alert_button),
                contentDescription = "AI Alert",
                tint = Color.Unspecified,
            )
        }
        IconButton(
            onClick = onAddClick,
            modifier
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_add),
                contentDescription = "일기 추가",
                tint = MPAColor.TEXT_PRIMARY.color(),
            )
        }
    }
}

@Composable
private fun GreetingHeader() {
    Column {
        Text(
            text = "좋은 아침이에요",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.TEXT_PRIMARY.color(),
            modifier = Modifier
                .padding(bottom = 2.dp)
        )
        Text(
            text = "10월 30일 금요일",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_TERTIARY.color(),
        )
    }
}

// ── AI question card ──────────────────────────────────────────────────
@Composable
private fun JournalQuestionCard() {
    AiCard {
        AiLabel("오늘의 조언", modifier = Modifier.padding(bottom = 10.dp))
        Text(
            text =
                "오늘 일기에 '끝까지 듣기'가 자주 보여요. " +
                "오늘은 대화가 화나를 몰라, 상대의 말이 끝" +
                "난 뒤 질문을 하나만 더 건네 보는 건 어때" +
                "요?",
            style = MaterialTheme.typography.bodyMedium,
            color = MPAColor.TEXT_PRIMARY.color(),
            modifier = Modifier.padding(bottom = 14.dp)
        )
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(bottom = 12.dp)
        ) {
            Text(
                text = "참고한 일기",
                style = MaterialTheme.typography.bodySmall,
                color = MPAColor.TEXT_TERTIARY.color(),
            )
            ChipPill("10월 20일")
            ChipPill("10월 27일")
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                text = "🔺 5가지 내 새로운 생성됨",
                style = MaterialTheme.typography.bodySmall,
                color = MPAColor.TEXT_SECONDARY.color(),
            )
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                ActionIcon(icons = ImageVector.vectorResource(R.drawable.ic_thumb_up))
                ActionIcon(icons = ImageVector.vectorResource(R.drawable.ic_thumb_down))
                ActionIcon(icons = ImageVector.vectorResource(R.drawable.ic_refresh))
            }
        }
    }
}

// ── AI reflection card ────────────────────────────────────────────────
@Composable
private fun JournalReflectionCard() {
    AiCard {
        AiLabel("오늘의 걸음")
        Spacer(Modifier.height(10.dp))
        Text(
            text = "오늘은 누군가의 말을 끝까지 들었던 순간이 있었나요?",
            style = MaterialTheme.typography.bodyMedium,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Spacer(Modifier.height(16.dp))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            PillButton("이 질문으로 쓰기", filled = true)
            PillButton("다른 질문", filled = false)
        }
    }
}

// ── My wish section ───────────────────────────────────────────────────
@Composable
private fun MyWishSection() {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                text = "나의 원칙",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Text(
                text = "전체 보기",
                style = MaterialTheme.typography.bodySmall,
                color = MPAColor.BRAND_PRIMARY.color(),
            )
        }
        Text(
            text = "일기 12개에서 찾았어요",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_TERTIARY.color(),
        )
        Spacer(Modifier.height(20.dp))
        BubbleCloud()
        Spacer(Modifier.height(8.dp))
        BubbleLegend()
    }
}

@Composable
private fun BubbleCloud() {
    Column {
        // Row 1: 무조함(64)  경청(100, center)  솔직함(72)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            PrincipleBubble("무조함", 64.dp, MPAColor.PRINCIPLE_5.color())
            PrincipleBubble("경청", 100.dp, MPAColor.PRINCIPLE_1.color())
            PrincipleBubble("솔직함", 72.dp, MPAColor.PRINCIPLE_4.color())
        }
        // Row 2: 휴식(80)  감사(68)
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            PrincipleBubble("휴식", 80.dp, MPAColor.PRINCIPLE_3.color())
            PrincipleBubble("감사", 68.dp, MPAColor.PRINCIPLE_2.color())
        }
    }
}

@Composable
private fun BubbleLegend() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Spacer(Modifier.weight(1f))
        Text(
            text = "최근",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_TERTIARY.color(),
        )
        MPAColor.entries
            .filter { it.name.startsWith("PRINCIPLE_") && it != MPAColor.ON_PRINCIPLE }
            .sortedBy { it.ordinal }
            .forEach { p -> Dot(p.color()) }
        Text(
            text = "오래된",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_TERTIARY.color(),
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = "크기 = 등장 빈도",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_TERTIARY.color(),
        )
        Spacer(Modifier.weight(1f))
    }
}

// ── Next week summary card ────────────────────────────────────────────
@Composable
private fun NextWeeksSummaryCard() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MPAColor.SUNKEN.color())
            .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "이전 주 요약",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Text(
                text = "10월 26일~30일 · 일기 4개 · 서분형이 늘었어요",
                style = MaterialTheme.typography.bodySmall,
                color = MPAColor.TEXT_SECONDARY.color(),
            )
        }
        Icon(
            ImageVector.vectorResource(R.drawable.ic_expand_more),
            contentDescription = null,
            modifier = Modifier.size(22.dp),
            tint = MPAColor.TEXT_PRIMARY.color()
        )
    }
}

// ── Shared helpers ────────────────────────────────────────────────────

/** Light-purple card that wraps every AI-driven section. */
@Composable
private fun AiCard(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MPAColor.AI_TINT.color())
            .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(16.dp))
            .padding(16.dp),
    ) {
        content()
    }
}

@Composable
private fun AiLabel(text: String, modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_sparkle),
            contentDescription = null,
            modifier = Modifier.size(14.dp)
        )
        Spacer(Modifier.width(4.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.labelMedium,
            color = MPAColor.AI_ACCENT.color(),
            fontWeight = FontWeight.Medium,
        )
    }
}

@Composable
private fun ChipPill(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelSmall,
        color = MPAColor.TEXT_SECONDARY.color(),
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(999.dp))
            .padding(horizontal = 10.dp, vertical = 4.dp),
    )
}

@Composable
private fun ActionIcon(icons: ImageVector) {
    Icon(
        imageVector = icons,
        contentDescription = null,
        tint = MPAColor.TEXT_SECONDARY.color(),
        modifier = Modifier.size(20.dp),
    )
}

@Composable
private fun PillButton(text: String, filled: Boolean) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelLarge,
        fontWeight = FontWeight.Medium,
        color =
            if (filled) MPAColor.BRAND_ON_PRIMARY.color()
            else MPAColor.TEXT_SECONDARY.color(),
        textAlign = TextAlign.Center,
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .then(
                if (filled) Modifier.background(MPAColor.BRAND_PRIMARY.color())
                else Modifier.border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(999.dp)),
            )
            .clickable { }
            .padding(horizontal = 18.dp, vertical = 10.dp),
    )
}

@Composable
private fun PrincipleBubble(
    label: String,
    size: Dp,
    color: Color,
) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(color),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = MPAColor.ON_PRINCIPLE.color(),
            fontWeight = FontWeight.Medium,
        )
    }
}

@Composable
private fun Dot(color: Color) {
    Box(
        modifier = Modifier
            .size(8.dp)
            .clip(CircleShape)
            .background(color),
    )
}

@Composable
fun TodayJournalPromptCard(
    prompt: String = "오늘 하루를 몇 줄로 남겨보세요",
    onClick: () -> Unit = {},
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MPAColor.SURFACE.color())
            .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(16.dp),
    ) {
        Text(
            text = "오늘의 일기",
            style = MaterialTheme.typography.labelSmall,
            color = MPAColor.TEXT_TERTIARY.color(),
            fontWeight = FontWeight.Medium,
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = prompt,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = "짧아도 괜찮아요. 오른쪽 아래 '쓰기'를 눌러 시작하세요.",
            style = MaterialTheme.typography.bodySmall,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
    }
}

// ── This week calendar strip ────────────────────────────────────────────
data class WeekDayCell(
    val dayOfWeek: String,
    val dayOfMonth: String,
    val isSelected: Boolean = false,
    val isCurrentWeek: Boolean = true,
    /** Journal dot under the date. */
    val hasJournal: Boolean = false,
)

@Composable
fun ThisWeekCalendarStrip(
    days: List<WeekDayCell>,
    onOpenCalendar: () -> Unit = {},
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                text = "이번 주",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            TextButton(onClick = onOpenCalendar) {
                Text(
                    text = "캘린더",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MPAColor.BRAND_PRIMARY.color(),
                )
            }
        }
        Spacer(Modifier.height(14.dp))
        Row(horizontalArrangement = Arrangement.SpaceBetween) {
            days.forEach { cell ->
                WeekDayColumn(cell = cell)
            }
        }
    }
}

@Composable
private fun WeekDayColumn(cell: WeekDayCell) {
    val muted = !cell.isCurrentWeek
    Column(
        modifier = Modifier
            .size(width = 50.dp, height = 64.dp)
            .clip(RoundedCornerShape(12.dp))
            .then(
                if (cell.isSelected) {
                    Modifier.background(MPAColor.BRAND_CONTAINER.color())
                } else {
                    Modifier
                }
            )
            .padding(vertical = 8.dp)
            .scrollable(rememberScrollState(), orientation = Orientation.Horizontal),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = cell.dayOfWeek,
            style = MaterialTheme.typography.bodySmall,
            color =
                if (muted) MPAColor.TEXT_TERTIARY.color()
                else MPAColor.TEXT_SECONDARY.color(),
            fontWeight = FontWeight.Medium,
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = cell.dayOfMonth,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold,
            color =
                if (muted) MPAColor.TEXT_TERTIARY.color()
                else MPAColor.TEXT_PRIMARY.color(),
        )
        Spacer(Modifier.height(4.dp))
        Box(
            modifier = Modifier.height(4.dp),
            contentAlignment = Alignment.Center,
        ) {
            if (cell.hasJournal) {
                Box(
                    modifier = Modifier
                        .size(4.dp)
                        .clip(CircleShape)
                        .background(
                            if (muted) MPAColor.TEXT_TERTIARY.color()
                            else MPAColor.BRAND_PRIMARY.color(),
                        ),
                )
            }
        }
    }
}

// ── Recent journal records ──────────────────────────────────────────────
data class RecentJournalItem(
    val dayOfMonth: String,
    val dayOfWeek: String,
    val title: String,
    val preview: String,
    val hasPhoto: Boolean = false,
)

@Composable
fun RecentJournalSection(
    items: List<RecentJournalItem>,
    onSeeAll: () -> Unit = {},
    onItemClick: (RecentJournalItem) -> Unit = {},
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                text = "최근 기록",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            TextButton(onClick = onSeeAll) {
                Text(
                    text = "모두 보기",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MPAColor.TEXT_PRIMARY.color(),
                )
            }
        }
        Spacer(Modifier.height(8.dp))
        items.forEachIndexed { index, item ->
            RecentJournalRow(item = item, onClick = { onItemClick(item) })
            if (index != items.lastIndex) {
                Spacer(Modifier.height(4.dp))
                HorizontalDivider(
                    color = MPAColor.HAIRLINE.color(),
                    thickness = 1.dp,
                )
                Spacer(Modifier.height(4.dp))
            }
        }
    }
}

@Composable
private fun RecentJournalRow(
    item: RecentJournalItem,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.Top,
    ) {
        // Date block
        Column(
            modifier = Modifier.width(44.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = item.dayOfMonth,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Text(
                text = item.dayOfWeek,
                style = MaterialTheme.typography.bodySmall,
                color = MPAColor.TEXT_TERTIARY.color(),
            )
        }
        Spacer(Modifier.width(14.dp))
        // Title + preview
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = item.preview,
                style = MaterialTheme.typography.bodyMedium,
                color = MPAColor.TEXT_SECONDARY.color(),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.width(12.dp))
        // Thumbnail placeholder
        if (item.hasPhoto) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(MPAColor.SUNKEN.color()),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_image_placeholder_glyph),
                    contentDescription = null,
                    tint = MPAColor.TEXT_TERTIARY.color(),
                    modifier = Modifier.size(22.dp),
                )
            }
        }
    }
}

@Preview
@Composable
private fun PreviewLightHomeView() {
    HomeView()
}
@Preview(uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun PreviewDarkHomeView() {
    HomeView()
}