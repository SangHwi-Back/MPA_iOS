// [NO AC] Spec: specs/home/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.ui.view.home

import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.view.HapticFeedbackConstants
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.*
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.mpa_android.R
import com.example.mpa_android.TopAppBarModel
import com.example.mpa_android.TopAppBarStyle
import com.example.mpa_android.model.*
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.ui.view.WRITE_FAB_RESERVED_HEIGHT
import com.example.mpa_android.ui.view.journal.JournalHelpResourceCard
import com.example.mpa_android.viewmodel.HomeUiState
import com.example.mpa_android.viewmodel.HomeViewModel
import kotlinx.coroutines.delay
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.TextStyle
import java.util.*
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private val GUTTER = 20.dp
private val CARD_RADIUS = 24.dp
private val CARD_PADDING = 20.dp
private val TOUCH_TARGET = 48.dp
private val BUBBLE_AREA_HEIGHT = 240.dp

private val principleColors = listOf(
    MPAColor.PRINCIPLE_1, MPAColor.PRINCIPLE_2, MPAColor.PRINCIPLE_3, MPAColor.PRINCIPLE_4, MPAColor.PRINCIPLE_5,
)

@Composable
private fun principleColor(stage: Int): Color = principleColors[stage.coerceIn(0, principleColors.lastIndex)].color()

/** Callbacks from 오늘 to the rest of the app. */
data class HomeActions(
    val onWrite: (date: LocalDate?, prompt: String?) -> Unit = { _, _ -> },
    val onOpenEntry: (Journal) -> Unit = {},
    val onOpenPrinciples: () -> Unit = {},
    val onOpenJournal: () -> Unit = {},
    val onConnectKey: () -> Unit = {},
)

/** Callbacks into [HomeViewModel]. */
private data class HomeModelActions(
    val onFeedback: (AIFeedback) -> Unit = {},
    val onRegenerateAdvice: () -> Unit = {},
    val onRetryAdvice: () -> Unit = {},
    val onNextPrompt: () -> Unit = {},
    val onToggleSummary: () -> Unit = {},
    val onRetrySummary: () -> Unit = {},
    val onAlertPresented: (Boolean) -> Unit = {},
    val onChangeWeek: (Int) -> Unit = {},
)

// ── Root ──────────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    aiConnection: AIConnectionState,
    actions: HomeActions,
    dynamicTopAppBar: (model: TopAppBarModel) -> Unit,
    onFabExpandedChange: (Boolean) -> Unit = {},
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()

    LaunchedEffect(aiConnection) { viewModel.setAIStatus(HomeAIStatus.from(aiConnection)) }

    // Large title "좋은 아침이에요" with the date as the M3 subtitle (3.2). Actions hold only the warning (3.12).
    val isAIAvailable = state.aiStatus.isAvailable
    LaunchedEffect(state.greeting, state.dateLine, isAIAvailable) {
        dynamicTopAppBar(
            TopAppBarModel(
                title = state.greeting,
                subTitle = state.dateLine,
                style = TopAppBarStyle.LARGE,
                scrollBehavior = { TopAppBarDefaults.exitUntilCollapsedScrollBehavior(rememberTopAppBarState()) },
                leadingSection = {},
                trailingSection = {
                    AnimatedVisibility(visible = !isAIAvailable, enter = scaleIn() + fadeIn(), exit = scaleOut() + fadeOut()) {
                        HomeWarningButton { viewModel.setAlertPresented(true) }
                    }
                },
            ),
        )
    }

    HomeContent(
        state = state,
        actions = actions,
        modelActions = HomeModelActions(
            onFeedback = viewModel::toggleFeedback,
            onRegenerateAdvice = viewModel::regenerateAdvice,
            onRetryAdvice = viewModel::generateAdvice,
            onNextPrompt = viewModel::nextPrompt,
            onToggleSummary = viewModel::toggleSummary,
            onRetrySummary = viewModel::generateSummary,
            onAlertPresented = viewModel::setAlertPresented,
            onChangeWeek = viewModel::changeWeek,
        ),
        onFabExpandedChange = onFabExpandedChange,
    )
}

/** Text for the shared FAB on 오늘 (3.1): "첫 일기 쓰기" / "이어 쓰기" / "쓰기". */
fun homeFabLabel(entries: List<Journal>, today: LocalDate = LocalDate.now()): String = when {
    entries.isEmpty() -> "첫 일기 쓰기"
    entries.any { it.day == today } -> "이어 쓰기"
    else -> "쓰기"
}

@Composable
private fun HomeWarningButton(onClick: () -> Unit) {
    IconButton(onClick = onClick, modifier = Modifier.size(TOUCH_TARGET)) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_alert_button),
            contentDescription = "AI 경고",
            tint = Color.Unspecified,
            modifier = Modifier.size(40.dp),
        )
    }
}

@Composable
private fun HomeContent(
    state: HomeUiState,
    actions: HomeActions,
    modelActions: HomeModelActions,
    onFabExpandedChange: (Boolean) -> Unit = {},
    showsHeader: Boolean = false,
) {
    val scrollState = rememberScrollState()
    // The FAB shrinks to its icon while scrolling down and expands again on the way up (3.1).
    LaunchedEffect(scrollState) {
        var previous = scrollState.value
        snapshotFlow { scrollState.value }.collect { value ->
            if (value != previous) onFabExpandedChange(value < previous || value == 0)
            previous = value
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
            .verticalScroll(scrollState)
            .padding(horizontal = GUTTER)
            .padding(top = 8.dp, bottom = 120.dp + WRITE_FAB_RESERVED_HEIGHT),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        // Previews draw the large title themselves; in the app it is the top app bar.
        if (showsHeader) HomePreviewHeader(state)
        when (state.layout) {
            HomeLayout.FIRST_RUN -> HomeFirstRun(state, actions)
            HomeLayout.EARLY -> {
                AdviceCard(state, actions, modelActions)
                TodayOrPromptCard(state, actions, modelActions)
                PrincipleProgress(state.entries.size, Modifier.padding(top = 16.dp))
            }
            HomeLayout.FULL -> {
                AdviceCard(state, actions, modelActions)
                TodayOrPromptCard(state, actions, modelActions)
                PrinciplesSection(state, actions, Modifier.padding(top = 24.dp))
                if (state.showsWeeklySummary) WeeklySummaryCard(state, actions, modelActions)
            }
            HomeLayout.DIARY -> {
                val today = state.todayEntry
                if (today != null) TodayPreviewCard(today) { actions.onOpenEntry(today) } else DiaryTodayCard()
                WeekStrip(state, actions, modelActions, Modifier.padding(top = 16.dp))
                RecentSection(state.recentEntries, actions, Modifier.padding(top = 16.dp))
            }
        }
    }

    val reason = (state.aiStatus as? HomeAIStatus.Unavailable)?.reason
    if (state.isAlertPresented && reason != null) {
        HomeAIAlert(
            reason = reason,
            onDismiss = { modelActions.onAlertPresented(false) },
            onConnectKey = {
                modelActions.onAlertPresented(false)
                actions.onConnectKey()
            },
        )
    }
}

/** Stand-in for the large top app bar in previews (title + subtitle, warning action). */
@Composable
private fun HomePreviewHeader(state: HomeUiState) {
    Column {
        Row(Modifier.fillMaxWidth().height(56.dp), horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
            if (!state.aiStatus.isAvailable) HomeWarningButton {}
        }
        Text(
            text = state.greeting,
            fontSize = 36.sp,
            fontWeight = FontWeight.Bold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Text(
            text = state.dateLine,
            fontSize = 16.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
    }
}

// ── Shared pieces ───────────────────────────────────────────────────────

@Composable
private fun AiLabel(text: String, fontSize: Int = 15, color: Color = MPAColor.AI_ACCENT.color()) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_sparkle),
            contentDescription = null,
            tint = MPAColor.AI_ACCENT.color(),
            modifier = Modifier.size((fontSize - 2).dp),
        )
        Text(text = text, fontSize = fontSize.sp, fontWeight = FontWeight.SemiBold, color = color)
    }
}

@Composable
private fun SurfaceCard(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CARD_RADIUS))
            .background(MPAColor.SURFACE.color())
            .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(CARD_RADIUS))
            .padding(CARD_PADDING),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) { content() }
}

/** Lavender AI card. Failure states switch to a neutral surface (Part B 4). */
@Composable
private fun AiCard(modifier: Modifier = Modifier, isNeutral: Boolean = false, content: @Composable () -> Unit) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CARD_RADIUS))
            .background(if (isNeutral) MPAColor.SUNKEN.color() else MPAColor.AI_TINT.color())
            .padding(CARD_PADDING)
            .animateContentSize(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) { content() }
}

@Composable
private fun SectionHeader(title: String, subtitle: String? = null, actionTitle: String? = null, onAction: () -> Unit = {}) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(
                text = title,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.semantics { heading() },
            )
            if (subtitle != null) {
                Text(text = subtitle, fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
            }
        }
        if (actionTitle != null) {
            TextButton(onClick = onAction) {
                Text(actionTitle, fontSize = 16.sp, color = MPAColor.BRAND_PRIMARY.color())
            }
        }
    }
}

/** "참고한 일기" chip: M3 assist chip shape (radius 8). */
@Composable
private fun SourceChip(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .heightIn(min = TOUCH_TARGET)
            .clickable(role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            fontSize = 14.sp,
            color = MPAColor.TEXT_PRIMARY.color(),
            modifier = Modifier
                .clip(RoundedCornerShape(8.dp))
                .background(MPAColor.SURFACE.color())
                .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(8.dp))
                .padding(horizontal = 16.dp, vertical = 7.dp),
        )
    }
}

@Composable
private fun SourceRow(sources: List<Journal>, onOpen: (Journal) -> Unit) {
    if (sources.isEmpty()) return
    FlowRow(
        verticalArrangement = Arrangement.Center,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        itemVerticalAlignment = Alignment.CenterVertically,
    ) {
        Text("참고한 일기", fontSize = 13.sp, color = MPAColor.TEXT_SECONDARY.color())
        sources.forEach { entry -> SourceChip(HomeViewModel.chipDate(entry.day)) { onOpen(entry) } }
    }
}

/** Word-by-word fade in (Part B 2, 120 ms per word). Screen readers get the full text at once. */
@Composable
private fun RevealText(text: String, revealsByWord: Boolean, fontSize: Int = 18) {
    val words = remember(text) { text.split(" ") }
    var visible by remember(text) { mutableStateOf(if (revealsByWord) 0 else Int.MAX_VALUE) }
    LaunchedEffect(text, revealsByWord) {
        if (!revealsByWord) { visible = Int.MAX_VALUE; return@LaunchedEffect }
        for (count in 1..words.size) {
            delay(120)
            visible = count
        }
    }
    val annotated: AnnotatedString = buildAnnotatedString {
        words.forEachIndexed { index, word ->
            val part = if (index == 0) word else " $word"
            if (index < visible) append(part) else withStyle(SpanStyle(color = Color.Transparent)) { append(part) }
        }
    }
    SelectionContainer {
        Text(
            text = annotated,
            fontSize = fontSize.sp,
            lineHeight = (fontSize * 1.6).sp,
            color = MPAColor.TEXT_PRIMARY.color(),
            modifier = Modifier.semantics { contentDescription = text },
        )
    }
}

@Composable
private fun Skeleton(lines: Int) {
    val alpha by animateFloatAsState(targetValue = 1f, label = "skeleton")
    Column(verticalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.alpha(alpha)) {
        repeat(lines) { index ->
            Box(
                Modifier
                    .fillMaxWidth(if (index == lines - 1) 0.6f else 1f)
                    .height(14.dp)
                    .clip(CircleShape)
                    .background(MPAColor.AI_ACCENT.color().copy(alpha = 0.12f)),
            )
        }
    }
}

@Composable
private fun FeedbackIcon(iconRes: Int, label: String, onClick: () -> Unit) {
    IconButton(onClick = onClick, modifier = Modifier.size(TOUCH_TARGET)) {
        Icon(
            imageVector = ImageVector.vectorResource(iconRes),
            contentDescription = label,
            tint = MPAColor.TEXT_SECONDARY.color(),
            modifier = Modifier.size(26.dp),
        )
    }
}

// ── 3.3 오늘의 조언 ─────────────────────────────────────────────────────

@Composable
private fun AdviceCard(state: HomeUiState, actions: HomeActions, modelActions: HomeModelActions) {
    val context = LocalContext.current
    val view = LocalView.current
    when (val phase = state.advicePhase) {
        HomeAIPhase.Sensitive -> JournalHelpResourceCard(
            onCall = { context.startActivity(Intent(Intent.ACTION_DIAL, "tel:109".toUri())) },
            onOpenResources = {},
        )
        HomeAIPhase.Failed -> AiCard(isNeutral = true) {
            Text("조언을 만들지 못했어요. 잠시 후 다시 시도해 주세요.", fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
            OutlinedButton(onClick = modelActions.onRetryAdvice) { Text("다시 시도", color = MPAColor.BRAND_PRIMARY.color()) }
        }
        HomeAIPhase.Resting -> AiCard(isNeutral = true) {
            Text("오늘은 쉬어 갈게요", fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
        }
        HomeAIPhase.KeyError -> AiCard(isNeutral = true) {
            Text("내 API 키를 확인해 주세요", fontSize = 17.sp, fontWeight = FontWeight.Bold, color = MPAColor.TEXT_PRIMARY.color())
            Text(
                "Gemini가 키를 받지 않았어요. 사용 한도를 넘었거나 키가 만료됐을 수 있어요.",
                fontSize = 15.sp,
                color = MPAColor.TEXT_SECONDARY.color(),
            )
            OutlinedButton(onClick = actions.onConnectKey) { Text("키 확인", color = MPAColor.BRAND_PRIMARY.color()) }
        }
        HomeAIPhase.Idle, HomeAIPhase.Loading, is HomeAIPhase.Loaded -> AiCard {
            AiLabel("오늘의 조언")
            val text = phase.text
            if (text == null) {
                Skeleton(lines = 3)
                Text("기기에서 만드는 중…", fontSize = 12.sp, color = MPAColor.TEXT_SECONDARY.color())
            } else {
                RevealText(text.text, state.revealsAdviceByWord)
                SourceRow(state.sources(text), actions.onOpenEntry)
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = text.engine.sourceLabel,
                        fontSize = 12.sp,
                        color = MPAColor.TEXT_SECONDARY.color(),
                        modifier = Modifier.weight(1f),
                    )
                    val confirm = {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                    }
                    // Picking one hides the other (Part B 3).
                    if (text.feedback != AIFeedback.NOT_HELPFUL) {
                        FeedbackIcon(
                            if (text.feedback == AIFeedback.HELPFUL) R.drawable.ic_thumb_up_filled else R.drawable.ic_thumb_up,
                            "도움됨",
                        ) { confirm(); modelActions.onFeedback(AIFeedback.HELPFUL) }
                    }
                    if (text.feedback != AIFeedback.HELPFUL) {
                        FeedbackIcon(
                            if (text.feedback == AIFeedback.NOT_HELPFUL) R.drawable.ic_thumb_down_filled else R.drawable.ic_thumb_down,
                            "도움 안 됨",
                        ) { confirm(); modelActions.onFeedback(AIFeedback.NOT_HELPFUL) }
                    }
                    FeedbackIcon(R.drawable.ic_refresh, "다시 생성", modelActions.onRegenerateAdvice)
                }
                if (text.feedback == AIFeedback.NOT_HELPFUL) {
                    TextButton(onClick = modelActions.onRegenerateAdvice) {
                        Text("다른 조언 보기", fontWeight = FontWeight.SemiBold, color = MPAColor.BRAND_PRIMARY.color())
                    }
                }
            }
        }
    }
}

// ── 3.6 오늘의 글감 / 3.7 오늘 일기 미리보기 ────────────────────────────

@Composable
private fun TodayOrPromptCard(state: HomeUiState, actions: HomeActions, modelActions: HomeModelActions) {
    val today = state.todayEntry
    if (today != null) {
        TodayPreviewCard(today) { actions.onOpenEntry(today) }
    } else {
        PromptCard(state.promptPhase, onWrite = { actions.onWrite(null, it) }, onNext = modelActions.onNextPrompt)
    }
}

@Composable
private fun PromptCard(phase: HomeAIPhase, onWrite: (String) -> Unit, onNext: () -> Unit) {
    SurfaceCard(Modifier.animateContentSize()) {
        AiLabel("오늘의 글감", fontSize = 14)
        val prompt = phase.text?.text
        when {
            prompt != null -> Text(prompt, fontSize = 22.sp, lineHeight = 32.sp, color = MPAColor.TEXT_PRIMARY.color())
            phase == HomeAIPhase.Failed -> Text("질문을 만들지 못했어요.", fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
            else -> Skeleton(lines = 2)
        }
        Row(
            modifier = Modifier.padding(top = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // The FAB handles plain writing, so the label names this button's role (3.6).
            Button(
                onClick = { prompt?.let(onWrite) },
                enabled = prompt != null,
                modifier = Modifier.heightIn(min = 48.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MPAColor.BRAND_PRIMARY.color(),
                    contentColor = MPAColor.BRAND_ON_PRIMARY.color(),
                ),
            ) { Text("쓰기", fontSize = 16.sp, fontWeight = FontWeight.SemiBold) }
            TextButton(onClick = onNext, enabled = phase != HomeAIPhase.Loading) {
                Text("다른 질문", fontSize = 16.sp, color = MPAColor.BRAND_PRIMARY.color())
            }
        }
    }
}

@Composable
private fun TodayPreviewCard(entry: Journal, onOpen: () -> Unit) {
    SurfaceCard(Modifier.clickable(onClickLabel = "오늘 일기 열기", onClick = onOpen)) {
        Row(Modifier.fillMaxWidth()) {
            Text(
                "오늘의 일기",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_SECONDARY.color(),
                modifier = Modifier.weight(1f),
            )
            Text(HomeViewModel.timeText(entry.createdAt), fontSize = 14.sp, color = MPAColor.TEXT_TERTIARY.color())
        }
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    entry.displayTitle,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif,
                    color = MPAColor.TEXT_PRIMARY.color(),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    entry.previewText,
                    fontSize = 16.sp,
                    lineHeight = 24.sp,
                    color = MPAColor.TEXT_SECONDARY.color(),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            if (entry.thumbnail != null) Thumbnail()
        }
    }
}

@Composable
private fun Thumbnail() {
    Box(
        modifier = Modifier
            .size(56.dp)
            .clip(RoundedCornerShape(14.dp))
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

// ── 3.8 나의 원칙 ───────────────────────────────────────────────────────

@Composable
private fun PrinciplesSection(state: HomeUiState, actions: HomeActions, modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SectionHeader(
            title = "나의 원칙",
            subtitle = "일기 ${state.entries.size}개에서 찾았어요",
            actionTitle = "전체 보기",
            onAction = actions.onOpenPrinciples,
        )
        BubbleCloud(state.principles, actions.onOpenEntry)
        BubbleLegend(Modifier.align(Alignment.CenterHorizontally))
    }
}

/** Slot centers (fractions) for the 1st…5th largest bubble, from the design. */
private val bubbleSlots = listOf(
    0.50f to 0.55f, 0.22f to 0.33f, 0.80f to 0.22f, 0.27f to 0.78f, 0.75f to 0.80f,
)

@Composable
private fun BubbleCloud(principles: List<HomePrinciple>, onOpenEntry: (Journal) -> Unit) {
    val ordered = principles.sortedByDescending { it.count }.take(bubbleSlots.size)
    val maxCount = ordered.firstOrNull()?.count ?: 1
    var appeared by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { appeared = true }
    BoxWithConstraints(
        Modifier
            .fillMaxWidth()
            .height(BUBBLE_AREA_HEIGHT),
    ) {
        ordered.forEachIndexed { index, principle ->
            val diameter = HomeViewModel.bubbleDiameter(principle.count, maxCount).dp
            val (fx, fy) = bubbleSlots[index]
            val x = (maxWidth * fx - diameter / 2).coerceIn(0.dp, maxWidth - diameter)
            val y = (maxHeight * fy - diameter / 2).coerceIn(0.dp, maxHeight - diameter)
            val rise by animateFloatAsState(
                targetValue = if (appeared) 0f else 40f,
                animationSpec = spring(dampingRatio = 0.7f),
                label = "bubbleRise",
            )
            PrincipleBubble(
                principle = principle,
                diameter = diameter,
                onOpenEntry = onOpenEntry,
                modifier = Modifier.offset(x = x, y = y + rise.dp),
            )
        }
    }
}

/** Tap opens a DropdownMenu anchored to the bubble: no blur or dim, focus ring on the bubble (3.8). */
@Composable
private fun PrincipleBubble(
    principle: HomePrinciple,
    diameter: androidx.compose.ui.unit.Dp,
    onOpenEntry: (Journal) -> Unit,
    modifier: Modifier = Modifier,
) {
    var expanded by remember { mutableStateOf(false) }
    val view = LocalView.current
    val stageText = if (principle.stage == 0) "최근" else "${principle.stage + 1}단계"
    Box(modifier) {
        Box(
            modifier = Modifier
                .size(diameter + 12.dp)
                .then(if (expanded) Modifier.border(2.dp, MPAColor.BRAND_PRIMARY.color(), CircleShape) else Modifier)
                .padding(6.dp)
                .clip(CircleShape)
                .background(principleColor(principle.stage))
                .clickable(role = Role.Button) {
                    view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
                    expanded = true
                }
                .semantics {
                    contentDescription = "원칙: ${principle.name}, $stageText, ${principle.count}개 일기에서 등장, 두 번 탭하여 관련 일기 보기"
                },
            contentAlignment = Alignment.Center,
        ) {
            Text(
                principle.name,
                fontSize = if (diameter > 100.dp) 22.sp else 18.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.ON_PRINCIPLE.color(),
                maxLines = 1,
            )
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            shape = RoundedCornerShape(16.dp),
            containerColor = MPAColor.SURFACE.color(),
            offset = DpOffset(0.dp, 4.dp),
        ) {
            Column(Modifier.padding(horizontal = 16.dp, vertical = 10.dp)) {
                Text(principle.name, fontSize = 17.sp, fontWeight = FontWeight.Bold, color = MPAColor.TEXT_PRIMARY.color())
                Text("${principle.count}개의 일기에서 발견", fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
            }
            HorizontalDivider(color = MPAColor.HAIRLINE.color())
            principle.related.forEach { entry ->
                DropdownMenuItem(
                    modifier = Modifier.heightIn(min = 56.dp),
                    text = {
                        Column {
                            Text(entry.displayTitle, fontSize = 16.sp, color = MPAColor.TEXT_PRIMARY.color(), maxLines = 1, overflow = TextOverflow.Ellipsis)
                            Text(HomeViewModel.dateLine(entry.day), fontSize = 13.sp, color = MPAColor.TEXT_SECONDARY.color())
                        }
                    },
                    onClick = {
                        expanded = false
                        onOpenEntry(entry)
                    },
                )
            }
        }
    }
}

/** 3.10 "최근 ● … ● 오래됨 · 크기 = 등장 빈도". */
@Composable
private fun BubbleLegend(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.semantics(mergeDescendants = true) { contentDescription = "색은 최근부터 오래된 순, 크기는 등장 빈도" },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        val style = MPAColor.TEXT_SECONDARY.color()
        Text("최근", fontSize = 13.sp, color = style)
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            principleColors.forEach { Box(Modifier.size(10.dp).clip(CircleShape).background(it.color())) }
        }
        Text("오래됨", fontSize = 13.sp, color = style)
        Text("·", fontSize = 13.sp, color = MPAColor.TEXT_TERTIARY.color())
        Text("크기 = 등장 빈도", fontSize = 13.sp, color = style)
    }
}

// ── 3.9 원칙 진행 표시 ─────────────────────────────────────────────────

@Composable
private fun PrincipleProgress(count: Int, modifier: Modifier = Modifier) {
    val threshold = HomeViewModel.PRINCIPLE_THRESHOLD
    val hairline = MPAColor.HAIRLINE.color()
    Column(modifier, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SectionHeader(title = "나의 원칙")
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(CARD_RADIUS))
                .drawDashedBorder(hairline)
                .padding(CARD_PADDING),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            val p1 = MPAColor.PRINCIPLE_1.color()
            val p3 = MPAColor.PRINCIPLE_3.color()
            val tertiary = MPAColor.TEXT_TERTIARY.color()
            Canvas(Modifier.size(64.dp)) {
                drawCircle(p1, radius = 20.dp.toPx(), center = Offset(22.dp.toPx(), 38.dp.toPx()), style = Stroke(2.dp.toPx()))
                drawCircle(p3, radius = 11.dp.toPx(), center = Offset(48.dp.toPx(), 18.dp.toPx()), style = Stroke(2.dp.toPx()))
                drawCircle(
                    tertiary, radius = 8.dp.toPx(), center = Offset(52.dp.toPx(), 54.dp.toPx()),
                    style = Stroke(1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(6f, 6f))),
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    "일기가 3개 이상 쌓이면\n원칙을 찾아드려요",
                    fontSize = 16.sp,
                    lineHeight = 24.sp,
                    color = MPAColor.TEXT_PRIMARY.color(),
                )
                Row(
                    modifier = Modifier.semantics(mergeDescendants = true) {
                        contentDescription = "원칙 분석까지 $count / $threshold"
                        progressBarRangeInfo = ProgressBarRangeInfo(count.toFloat(), 0f..threshold.toFloat(), threshold)
                    },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    repeat(threshold) { index ->
                        Box(
                            Modifier
                                .size(width = 28.dp, height = 6.dp)
                                .clip(CircleShape)
                                .background(if (index < count) MPAColor.BRAND_PRIMARY.color() else MPAColor.SUNKEN.color()),
                        )
                    }
                    Text("$count / $threshold", fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
                }
            }
        }
    }
}

/** Dashed outline for the empty principle card. */
private fun Modifier.drawDashedBorder(color: Color): Modifier = drawBehind {
    drawRoundRect(
        color = color,
        style = Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(14f, 10f))),
        cornerRadius = CornerRadius(CARD_RADIUS.toPx()),
    )
}

// ── 3.11 이번 주 요약 ───────────────────────────────────────────────────

@Composable
private fun WeeklySummaryCard(state: HomeUiState, actions: HomeActions, modelActions: HomeModelActions) {
    val phase = state.summaryPhase
    AiCard(
        modifier = Modifier
            .clickable(onClick = modelActions.onToggleSummary)
            .semantics { stateDescription = if (state.isSummaryExpanded) "펼쳐짐" else "접힘" },
        isNeutral = phase == HomeAIPhase.Failed || phase == HomeAIPhase.Resting,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                AiLabel("이번 주 요약", fontSize = 20, color = MPAColor.TEXT_PRIMARY.color())
                Text(
                    listOf(state.weeklyRangeLine, HomeSamples.WEEKLY_MOOD).filter { it.isNotEmpty() }.joinToString(" · "),
                    fontSize = 14.sp,
                    color = MPAColor.TEXT_SECONDARY.color(),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            val rotation by animateFloatAsState(if (state.isSummaryExpanded) 180f else 0f, label = "chevron")
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_expand_more),
                contentDescription = null,
                tint = MPAColor.TEXT_SECONDARY.color(),
                modifier = Modifier.size(28.dp).rotate(rotation),
            )
        }
        if (state.isSummaryExpanded) {
            when (phase) {
                is HomeAIPhase.Loaded -> {
                    Text(phase.text.text, fontSize = 16.sp, lineHeight = 26.sp, color = MPAColor.TEXT_PRIMARY.color())
                    SourceRow(state.sources(phase.text), actions.onOpenEntry)
                }
                HomeAIPhase.Failed -> {
                    Text("요약을 만들지 못했어요. 잠시 후 다시 시도해 주세요.", fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
                    OutlinedButton(onClick = modelActions.onRetrySummary) { Text("다시 시도", color = MPAColor.BRAND_PRIMARY.color()) }
                }
                HomeAIPhase.Resting -> Text("오늘은 쉬어 갈게요", fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
                else -> Skeleton(lines = 3)
            }
        }
    }
}

// ── 3.13 일기 앱 모드 ───────────────────────────────────────────────────

/** Android has no button here: the FAB handles writing (3.13). */
@Composable
private fun DiaryTodayCard() {
    SurfaceCard {
        Text("오늘의 일기", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = MPAColor.TEXT_SECONDARY.color())
        Text("오늘 하루를 몇 줄로 남겨보세요", fontSize = 22.sp, color = MPAColor.TEXT_PRIMARY.color())
        Text("짧아도 괜찮아요. 오른쪽 아래 ‘쓰기’를 눌러 시작하세요.", fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
    }
}

@Composable
private fun WeekStrip(state: HomeUiState, actions: HomeActions, modelActions: HomeModelActions, modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionHeader(title = "이번 주", actionTitle = "캘린더", onAction = actions.onOpenJournal)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .pointerInput(Unit) {
                    var total = 0f
                    detectHorizontalDragGestures(
                        onDragStart = { total = 0f },
                        onDragEnd = {
                            if (total > 80f) modelActions.onChangeWeek(-1)
                            if (total < -80f) modelActions.onChangeWeek(1)
                        },
                    ) { _, amount -> total += amount }
                },
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            state.weekDays.forEach { day ->
                WeekDayCell(day, Modifier.weight(1f)) {
                    val entry = HomeViewModel.newestFirst(state.entries).firstOrNull { it.day == day.date }
                    if (entry != null) actions.onOpenEntry(entry) else actions.onWrite(day.date, null)
                }
            }
        }
    }
}

/** Today is a filled container (#DCE0F4); future days are dimmed and disabled (3.13). */
@Composable
private fun WeekDayCell(day: HomeWeekDay, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val weekday = day.date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.KOREAN)
    val dayColor = when {
        day.isToday -> MPAColor.BRAND_ON_CONTAINER.color()
        day.isFuture -> MPAColor.TEXT_TERTIARY.color()
        else -> MPAColor.TEXT_PRIMARY.color()
    }
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(if (day.isToday) MPAColor.BRAND_CONTAINER.color() else Color.Transparent)
            .clickable(enabled = !day.isFuture, onClick = onClick)
            .padding(vertical = 10.dp)
            .semantics(mergeDescendants = true) {
                contentDescription = HomeViewModel.dateLine(day.date) + if (day.hasEntry) ", 일기 있음" else ""
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(
            weekday,
            fontSize = 13.sp,
            fontWeight = if (day.isToday) FontWeight.Bold else FontWeight.Normal,
            color = if (day.isToday) MPAColor.BRAND_ON_CONTAINER.color() else MPAColor.TEXT_SECONDARY.color(),
        )
        Text("${day.date.dayOfMonth}", fontSize = 20.sp, fontWeight = if (day.isToday) FontWeight.Bold else FontWeight.Normal, color = dayColor)
        Box(
            Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(if (day.hasEntry) MPAColor.BRAND_PRIMARY.color() else Color.Transparent),
        )
    }
}

@Composable
private fun RecentSection(entries: List<Journal>, actions: HomeActions, modifier: Modifier = Modifier) {
    Column(modifier) {
        SectionHeader(title = "최근 기록", actionTitle = "모두 보기", onAction = actions.onOpenJournal)
        entries.forEachIndexed { index, entry ->
            RecentRow(entry) { actions.onOpenEntry(entry) }
            if (index < entries.lastIndex) HorizontalDivider(color = MPAColor.HAIRLINE.color())
        }
    }
}

/** Date block + title + 2-line body + thumbnail. No keyword chips (3.13). */
@Composable
private fun RecentRow(entry: Journal, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(Modifier.width(44.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("${entry.day.dayOfMonth}", fontSize = 30.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Serif, color = MPAColor.TEXT_PRIMARY.color())
            Text(entry.day.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.KOREAN), fontSize = 13.sp, color = MPAColor.TEXT_SECONDARY.color())
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(entry.displayTitle, fontSize = 18.sp, fontWeight = FontWeight.Bold, color = MPAColor.TEXT_PRIMARY.color(), maxLines = 2, overflow = TextOverflow.Ellipsis)
            Text(entry.previewText, fontSize = 15.sp, lineHeight = 22.sp, color = MPAColor.TEXT_SECONDARY.color(), maxLines = 2, overflow = TextOverflow.Ellipsis)
        }
        if (entry.thumbnail != null) Thumbnail()
    }
}

// ── 3.14 첫 실행 ───────────────────────────────────────────────────────

/** No in-screen button on Android: the "첫 일기 쓰기" FAB does it (3.14). */
@Composable
private fun HomeFirstRun(state: HomeUiState, actions: HomeActions) {
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_empty_journal),
            contentDescription = null,
            tint = Color.Unspecified,
            modifier = Modifier.padding(vertical = 16.dp).size(200.dp),
        )
        Text("첫 일기를 써보세요", fontSize = 26.sp, fontWeight = FontWeight.Bold, color = MPAColor.TEXT_PRIMARY.color())
        Text(
            "몇 줄이면 충분해요. 일기가 쌓이면\n그 안에서 나만의 원칙을 찾아드릴게요.",
            fontSize = 16.sp,
            lineHeight = 24.sp,
            textAlign = TextAlign.Center,
            color = MPAColor.TEXT_SECONDARY.color(),
            modifier = Modifier.padding(top = 10.dp),
        )
        Column(Modifier.fillMaxWidth().padding(top = 32.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("이런 질문으로 시작해 보세요", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = MPAColor.TEXT_SECONDARY.color())
            HomeSamples.exampleQuestions.forEach { question ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 56.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(MPAColor.SURFACE.color())
                        .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(16.dp))
                        .clickable { actions.onWrite(null, question) }
                        .padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(question, fontSize = 16.sp, color = MPAColor.TEXT_PRIMARY.color(), modifier = Modifier.weight(1f))
                    Icon(
                        imageVector = ImageVector.vectorResource(R.drawable.ic_chevron_right),
                        contentDescription = null,
                        tint = MPAColor.TEXT_TERTIARY.color(),
                    )
                }
            }
        }
        val privacy = when (val status = state.aiStatus) {
            is HomeAIStatus.Unavailable -> null
            else -> if (status.engine?.isOnDevice == true) "모든 분석은 이 기기 안에서 이루어져요"
            else "요약·키워드만 ${if (status.engine == AIEngine.OPENAI_API_KEY) "OpenAI" else "Gemini"}(내 키)로 전송돼요"
        }
        if (privacy != null) {
            Row(Modifier.padding(top = 20.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_settings_lock),
                    contentDescription = null,
                    tint = MPAColor.TEXT_SECONDARY.color(),
                    modifier = Modifier.size(16.dp),
                )
                Text(privacy, fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
            }
        }
    }
}

// ── 3.12 AI 경고 ───────────────────────────────────────────────────────

/** M3 AlertDialog: warning icon, centered title, 확인 rightmost. Scrim tap and back dismiss it. */
@Composable
private fun HomeAIAlert(reason: AIUnavailableReason, onDismiss: () -> Unit, onConnectKey: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_alert_dialog),
                contentDescription = null,
                tint = MPAColor.WARNING_TEXT.color(),
            )
        },
        title = { Text(reason.homeAlertTitle, textAlign = TextAlign.Center) },
        text = { Text(reason.homeAlertMessage, color = MPAColor.TEXT_SECONDARY.color()) },
        confirmButton = { TextButton(onClick = onDismiss) { Text("확인", color = MPAColor.BRAND_PRIMARY.color()) } },
        dismissButton = { TextButton(onClick = onConnectKey) { Text("API 키 연결", color = MPAColor.BRAND_PRIMARY.color()) } },
        containerColor = MPAColor.CONTAINER.color(),
    )
}

// ── Previews ───────────────────────────────────────────────────────────

private val PREVIEW_NOW: LocalDateTime = LocalDateTime.of(2026, 10, 30, 8, 12)

private fun previewText(text: String, sources: List<Journal>) = AIText(
    text = text,
    engine = AIEngine.GEMINI_NANO,
    generatedAt = Instant.parse("2026-10-29T23:12:00Z"),
    sourceJournalIds = sources.map { it.id },
)

private fun previewState(
    entries: List<Journal>,
    status: HomeAIStatus = HomeAIStatus.Available(AIEngine.GEMINI_NANO),
    isAlertPresented: Boolean = false,
): HomeUiState {
    val isShort = entries.size < HomeViewModel.PRINCIPLE_THRESHOLD
    val sources = if (isShort) entries.sortedBy { it.day } else entries.filter { it.day.dayOfMonth in setOf(20, 27) }
    return HomeUiState(
        entries = entries,
        aiStatus = status,
        now = PREVIEW_NOW,
        advicePhase = HomeAIPhase.Loaded(previewText(if (isShort) HomeSamples.SHORT_ADVICE else HomeSamples.ADVICE, sources)),
        promptPhase = HomeAIPhase.Loaded(previewText(HomeSamples.WRITING_PROMPT, emptyList())),
        summaryPhase = HomeAIPhase.Loaded(previewText(HomeSamples.WEEKLY_SUMMARY, emptyList())),
        isAlertPresented = isAlertPresented,
    )
}

/** 3+ entries with nothing today, so the 글감 card shows. */
private val fullSamples get() = JournalSamples.list.filter { it.day.dayOfMonth != 30 }

@Composable
private fun PreviewHome(state: HomeUiState) {
    HomeContent(state = state, actions = HomeActions(), modelActions = HomeModelActions(), showsHeader = true)
}

@Preview(name = "home", heightDp = 1300)
@Composable
private fun PreviewHomeDefault() = PreviewHome(previewState(fullSamples))

@Preview(name = "noJournalToday", heightDp = 1300)
@Composable
private fun PreviewNoJournalToday() = PreviewHome(previewState(fullSamples))

@Preview(name = "todayJournalExist", heightDp = 1000)
@Composable
private fun PreviewTodayJournalExist() = PreviewHome(previewState(JournalSamples.homeEarly))

@Preview(name = "emptyJournals", heightDp = 1000)
@Composable
private fun PreviewEmptyJournals() = PreviewHome(previewState(emptyList()))

@Preview(name = "aiNotAvailable", heightDp = 1000)
@Composable
private fun PreviewAiNotAvailable() =
    PreviewHome(previewState(JournalSamples.homeDiary, HomeAIStatus.Unavailable(AIUnavailableReason.UNSUPPORTED)))

@Preview(name = "aiNotAvailableButtonTapped", heightDp = 1000)
@Composable
private fun PreviewAiNotAvailableButtonTapped() = PreviewHome(
    previewState(JournalSamples.homeDiary, HomeAIStatus.Unavailable(AIUnavailableReason.UNSUPPORTED), isAlertPresented = true),
)

@Preview(name = "bubbleLongTap", heightDp = 1300)
@Composable
private fun PreviewBubbleLongTap() {
    // Tap 경청 in interactive mode to open its menu.
    PreviewHome(previewState(fullSamples))
}

@Preview(name = "darkMode", heightDp = 1300, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun PreviewDarkMode() = PreviewHome(previewState(fullSamples))
