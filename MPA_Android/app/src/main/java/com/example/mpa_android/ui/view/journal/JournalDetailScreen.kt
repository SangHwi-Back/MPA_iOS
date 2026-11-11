// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class, ExperimentalMaterial3Api::class)

package com.example.mpa_android.ui.view.journal

import android.content.Intent
import android.view.HapticFeedbackConstants
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SelectableDates
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.mpa_android.R
import com.example.mpa_android.model.AIEngine
import com.example.mpa_android.model.AIFeedback
import com.example.mpa_android.model.AIText
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalKeywordSummary
import com.example.mpa_android.model.JournalPhoto
import com.example.mpa_android.model.JournalSamples
import com.example.mpa_android.model.PRINCIPLE_STAGE_COUNT
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.ui.theme.MPA_AndroidTheme
import com.example.mpa_android.viewmodel.JournalCommentPhase
import com.example.mpa_android.viewmodel.JournalDetailUiState
import com.example.mpa_android.viewmodel.JournalDetailViewModel
import com.example.mpa_android.viewmodel.JournalKeywordRow
import java.time.Instant as JavaInstant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import kotlin.time.ExperimentalTime
import kotlin.time.Instant
import kotlinx.coroutines.delay

private val GUTTER = 20.dp
private val READABLE_WIDTH = 680.dp
private val CHIP_HEIGHT = 32.dp
private val PHOTO_SPACING = 8.dp
private val PHOTO_RADIUS = 12.dp
private val CARD_RADIUS = 24.dp
private val COMMENT_HEADER_HEIGHT = 56.dp
private val ACTION_SIZE = 48.dp
private val SHEET_ROW_HEIGHT = 56.dp
private const val BODY_SIZE = 17
private const val BODY_LINE_HEIGHT = 1.75f

/** Alternating tints so neighboring photo placeholders read as separate tiles. */
private val PHOTO_PLACEHOLDERS = listOf(Color(0xFFD7DBE4), Color(0xFFDED6CB))

private data class JournalDetailActions(
    val onBack: () -> Unit = {},
    val onEdit: (Journal) -> Unit = {},
    val onDelete: (Journal) -> Unit = {},
    val onShare: (Journal) -> Unit = {},
    val onChangeDay: (LocalDate) -> Unit = {},
    val onToggleComment: () -> Unit = {},
    val onRetryComment: () -> Unit = {},
    val onRegenerateComment: () -> Unit = {},
    val onFeedback: (AIFeedback) -> Unit = {},
    val onPresentKeyword: (String?) -> Unit = {},
    val onOpenEntry: (Journal) -> Unit = {},
    val onOpenPrinciple: (String) -> Unit = {},
    val onOpenPhoto: (Journal, Int) -> Unit = { _, _ -> },
    val onCallHelpLine: () -> Unit = {},
    val onOpenHelpResources: () -> Unit = {},
)

/** Part B — reads one entry. Editing happens in the editor. */
@Composable
fun JournalDetailScreen(
    onBack: () -> Unit,
    onEdit: (Journal) -> Unit,
    onDelete: (Journal) -> Unit,
    onOpenEntry: (Journal) -> Unit,
    onOpenPrinciple: (String) -> Unit = {},
    onOpenPhoto: (Journal, Int) -> Unit = { _, _ -> },
    onOpenHelpResources: () -> Unit = {},
    viewModel: JournalDetailViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    JournalDetailContent(
        state = state,
        actions = JournalDetailActions(
            onBack = onBack,
            onEdit = onEdit,
            onDelete = onDelete,
            onShare = { journal ->
                val text = listOf(journal.title, journal.body).filter { it.isNotBlank() }.joinToString("\n\n")
                val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
                context.startActivity(Intent.createChooser(send, null))
            },
            onChangeDay = viewModel::changeDay,
            onToggleComment = viewModel::toggleComment,
            onRetryComment = viewModel::generateComment,
            onRegenerateComment = viewModel::regenerateComment,
            onFeedback = viewModel::toggleFeedback,
            onPresentKeyword = viewModel::presentKeyword,
            onOpenEntry = onOpenEntry,
            onOpenPrinciple = onOpenPrinciple,
            onOpenPhoto = onOpenPhoto,
            onCallHelpLine = { context.startActivity(Intent(Intent.ACTION_DIAL, "tel:109".toUri())) },
            onOpenHelpResources = onOpenHelpResources,
        ),
    )
}

@Composable
private fun JournalDetailContent(
    state: JournalDetailUiState,
    actions: JournalDetailActions,
    startsAtBottom: Boolean = false,
    zone: ZoneId = ZoneId.systemDefault(),
) {
    val journal = state.journal
    val scrollState = rememberScrollState()
    var titleBottom by remember { mutableIntStateOf(-1) }
    var isDatePickerVisible by remember { mutableStateOf(false) }

    LaunchedEffect(startsAtBottom, scrollState.maxValue) {
        if (startsAtBottom) scrollState.scrollTo(scrollState.maxValue)
    }

    // The date replaces the title in the bar when there is no title or it has scrolled away.
    val isTitleScrolledAway = state.hasTitle && titleBottom >= 0 && scrollState.value > titleBottom
    val barTitle = if (journal != null && (!state.hasTitle || isTitleScrolledAway)) {
        JournalDetailViewModel.shortDate(journal.day)
    } else {
        ""
    }

    Scaffold(
        containerColor = MPAColor.CANVAS.color(),
        topBar = {
            JournalDetailTopBar(
                title = barTitle,
                isScrolled = scrollState.value > 0,
                onBack = actions.onBack,
                onEdit = { journal?.let(actions.onEdit) },
                onShare = { journal?.let(actions.onShare) },
                onChangeDay = { isDatePickerVisible = true },
                onDelete = { journal?.let(actions.onDelete) },
            )
        },
    ) { innerPadding ->
        if (journal == null) return@Scaffold
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(scrollState),
            contentAlignment = Alignment.TopCenter,
        ) {
            Column(
                modifier = Modifier
                    .widthIn(max = READABLE_WIDTH)
                    .fillMaxWidth()
                    .padding(horizontal = GUTTER)
                    .padding(top = 8.dp, bottom = 48.dp),
            ) {
                if (state.isAIAvailable) {
                    JournalDetailKeywordRow(state, onClick = { actions.onPresentKeyword(it) })
                }

                Text(
                    text = JournalDetailViewModel.dateLine(journal.day, journal.createdAt, zone),
                    fontSize = 15.sp,
                    color = MPAColor.TEXT_SECONDARY.color(),
                )

                if (state.hasTitle) {
                    Text(
                        text = journal.title,
                        modifier = Modifier
                            .padding(top = 8.dp)
                            .semantics { heading() }
                            .onGloballyPositioned { titleBottom = (it.positionInParent().y + it.size.height).toInt() },
                        fontSize = 28.sp,
                        lineHeight = 36.sp,
                        fontFamily = FontFamily.Serif,
                        fontWeight = FontWeight.Bold,
                        color = MPAColor.TEXT_PRIMARY.color(),
                    )
                }

                JournalDetailBody(
                    paragraphs = JournalDetailViewModel.paragraphs(journal.body),
                    modifier = Modifier.padding(top = if (state.hasTitle) 22.dp else 12.dp),
                )

                if (journal.photos.isNotEmpty()) {
                    JournalDetailPhotoGrid(
                        photos = journal.photos,
                        onOpenPhoto = { actions.onOpenPhoto(journal, it) },
                        modifier = Modifier.padding(top = 28.dp),
                    )
                }

                if (state.isSensitive) {
                    JournalHelpResourceCard(
                        onCall = actions.onCallHelpLine,
                        onOpenResources = actions.onOpenHelpResources,
                        modifier = Modifier.padding(top = 28.dp),
                    )
                } else if (state.isAIAvailable) {
                    JournalCommentCard(state, actions, modifier = Modifier.padding(top = 28.dp))
                }

                journal.editedAt?.let { editedAt ->
                    Text(
                        text = JournalDetailViewModel.editedLine(editedAt, zone),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 24.dp),
                        fontSize = 13.sp,
                        textAlign = TextAlign.Center,
                        color = MPAColor.TEXT_SECONDARY.color(),
                    )
                }
            }
        }
    }

    state.presentedSummary?.let { summary ->
        JournalKeywordSheet(
            summary = summary,
            currentJournalId = journal?.id?.toString(),
            onDismiss = { actions.onPresentKeyword(null) },
            onOpenPrinciple = {
                actions.onPresentKeyword(null)
                actions.onOpenPrinciple(summary.name)
            },
            onOpenEntry = { entry ->
                actions.onPresentKeyword(null)
                actions.onOpenEntry(entry)
            },
        )
    }

    if (isDatePickerVisible && journal != null) {
        JournalDetailDatePicker(
            initialDay = journal.day,
            onConfirm = { day ->
                isDatePickerVisible = false
                actions.onChangeDay(day)
            },
            onDismiss = { isDatePickerVisible = false },
        )
    }
}

// ---- Top bar ----

@Composable
private fun JournalDetailTopBar(
    title: String,
    isScrolled: Boolean,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onShare: () -> Unit,
    onChangeDay: () -> Unit,
    onDelete: () -> Unit,
) {
    var isMenuOpen by remember { mutableStateOf(false) }
    val iconColor = MPAColor.TEXT_PRIMARY.color()
    TopAppBar(
        title = { Text(text = title, fontSize = 22.sp, maxLines = 1, overflow = TextOverflow.Ellipsis) },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(ImageVector.vectorResource(R.drawable.ic_arrow_back), contentDescription = "뒤로", tint = iconColor)
            }
        },
        actions = {
            IconButton(onClick = onEdit) {
                Icon(ImageVector.vectorResource(R.drawable.ic_edit), contentDescription = "편집", tint = iconColor)
            }
            Box {
                IconButton(onClick = { isMenuOpen = true }) {
                    Icon(ImageVector.vectorResource(R.drawable.ic_more_vert), contentDescription = "더보기", tint = iconColor)
                }
                DropdownMenu(
                    expanded = isMenuOpen,
                    onDismissRequest = { isMenuOpen = false },
                    containerColor = MPAColor.CONTAINER.color(),
                ) {
                    DropdownMenuItem(text = { Text("공유") }, onClick = { isMenuOpen = false; onShare() })
                    DropdownMenuItem(text = { Text("날짜 변경") }, onClick = { isMenuOpen = false; onChangeDay() })
                    DropdownMenuItem(
                        text = { Text("삭제", color = MPAColor.DANGER.color()) },
                        onClick = { isMenuOpen = false; onDelete() },
                    )
                }
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(
            // The bar turns surface container once the content scrolls under it.
            containerColor = if (isScrolled) MPAColor.CONTAINER.color() else MPAColor.CANVAS.color(),
            titleContentColor = MPAColor.TEXT_PRIMARY.color(),
        ),
    )
}

// ---- Keywords ----

@Composable
private fun principleStageColor(stage: Int): Color = listOf(
    MPAColor.PRINCIPLE_1,
    MPAColor.PRINCIPLE_2,
    MPAColor.PRINCIPLE_3,
    MPAColor.PRINCIPLE_4,
    MPAColor.PRINCIPLE_5,
)[stage.coerceIn(0, PRINCIPLE_STAGE_COUNT - 1)].color()

@Composable
private fun JournalDetailKeywordRow(state: JournalDetailUiState, onClick: (String) -> Unit) {
    when (val row = state.keywordRow) {
        JournalKeywordRow.Hidden -> Unit
        JournalKeywordRow.Skeleton -> Row(
            modifier = Modifier
                .padding(bottom = 24.dp)
                .semantics { contentDescription = "키워드를 찾는 중" },
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            listOf(64.dp, 84.dp).forEach { width ->
                Box(
                    Modifier
                        .size(width = width, height = CHIP_HEIGHT)
                        .clip(RoundedCornerShape(8.dp))
                        .background(MPAColor.AI_TINT.color()),
                )
            }
        }
        is JournalKeywordRow.Chips -> Row(
            modifier = Modifier
                .padding(bottom = 24.dp)
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            row.keywords.forEach { keyword ->
                JournalDetailKeywordChip(
                    name = keyword.name,
                    stage = state.keywordStages[keyword.name] ?: 0,
                    onClick = { onClick(keyword.name) },
                )
            }
        }
    }
}

/** M3 Assist chip look: radius 8 with a 1dp outline. */
@Composable
private fun JournalDetailKeywordChip(name: String, stage: Int, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .heightIn(min = 48.dp)
            .clip(RoundedCornerShape(8.dp))
            .clickable(role = Role.Button, onClickLabel = "이 키워드가 나온 일기 보기", onClick = onClick)
            .semantics { contentDescription = "키워드 $name" },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            modifier = Modifier
                .height(CHIP_HEIGHT)
                .clip(RoundedCornerShape(8.dp))
                .background(MPAColor.AI_TINT.color())
                .border(1.dp, MPAColor.AI_ACCENT.color().copy(alpha = 0.2f), RoundedCornerShape(8.dp))
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Box(Modifier.size(8.dp).clip(CircleShape).background(principleStageColor(stage)))
            Text(text = name, fontSize = 15.sp, color = MPAColor.AI_ACCENT.color())
        }
    }
}

// ---- Body and photos ----

@Composable
private fun JournalDetailBody(paragraphs: List<String>, modifier: Modifier = Modifier) {
    SelectionContainer(modifier = modifier) {
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            paragraphs.forEach { paragraph ->
                Text(
                    text = paragraph,
                    fontSize = BODY_SIZE.sp,
                    lineHeight = (BODY_SIZE * BODY_LINE_HEIGHT).sp,
                    color = MPAColor.TEXT_PRIMARY.color(),
                )
            }
        }
    }
}

@Composable
private fun JournalDetailPhotoGrid(photos: List<JournalPhoto>, onOpenPhoto: (Int) -> Unit, modifier: Modifier = Modifier) {
    if (photos.size == 1) {
        JournalDetailPhoto(photos.first(), 0, aspectRatio = 4f / 3f, onClick = { onOpenPhoto(0) }, modifier = modifier)
        return
    }
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        photos.withIndex().chunked(2).forEach { pair ->
            Row(horizontalArrangement = Arrangement.spacedBy(PHOTO_SPACING)) {
                pair.forEach { (index, photo) ->
                    JournalDetailPhoto(photo, index, aspectRatio = 1f, onClick = { onOpenPhoto(index) }, modifier = Modifier.weight(1f))
                }
                if (pair.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun JournalDetailPhoto(photo: JournalPhoto, index: Int, aspectRatio: Float, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(aspectRatio)
                .clip(RoundedCornerShape(PHOTO_RADIUS))
                .background(PHOTO_PLACEHOLDERS[index % PHOTO_PLACEHOLDERS.size])
                .clickable(role = Role.Image, onClick = onClick)
                .semantics { contentDescription = photo.caption.ifBlank { "사진 ${index + 1}" } },
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_image_placeholder_glyph),
                contentDescription = null,
                tint = Color.Unspecified,
                modifier = Modifier.size(24.dp),
            )
        }
        if (photo.caption.isNotBlank()) {
            Text(text = photo.caption, fontSize = 13.sp, color = MPAColor.TEXT_SECONDARY.color())
        }
    }
}

// ---- AI comment ----

@Composable
private fun JournalCommentCard(state: JournalDetailUiState, actions: JournalDetailActions, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CARD_RADIUS))
            .background(MPAColor.AI_TINT.color())
            .animateContentSize(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(COMMENT_HEADER_HEIGHT)
                .clickable(role = Role.Button, onClick = actions.onToggleComment)
                .semantics { stateDescription = if (state.isCommentExpanded) "펼쳐짐" else "접힘" }
                .padding(horizontal = GUTTER),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_sparkle),
                contentDescription = null,
                tint = MPAColor.AI_ACCENT.color(),
                modifier = Modifier.size(14.dp),
            )
            Text(
                text = "이 일기에 대한 AI 한마디",
                modifier = Modifier.weight(1f),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_expand_more),
                contentDescription = null,
                tint = MPAColor.TEXT_SECONDARY.color(),
                modifier = Modifier
                    .size(24.dp)
                    .rotate(if (state.isCommentExpanded) 180f else 0f),
            )
        }

        AnimatedVisibility(visible = state.isCommentExpanded) {
            Column(modifier = Modifier.padding(start = GUTTER, end = 8.dp, bottom = 12.dp)) {
                when (val phase = state.commentPhase) {
                    JournalCommentPhase.Idle, JournalCommentPhase.Loading -> JournalCommentSkeleton()
                    is JournalCommentPhase.Loaded -> {
                        JournalCommentText(phase.comment.text, state.revealsCommentByWord)
                        JournalCommentFooter(phase.comment, actions)
                    }
                    JournalCommentPhase.Failed -> {
                        Text(
                            text = "AI 한마디를 만들지 못했어요.",
                            fontSize = 15.sp,
                            color = MPAColor.TEXT_SECONDARY.color(),
                        )
                        TextButton(onClick = actions.onRetryComment) {
                            Text("다시 시도", color = MPAColor.BRAND_PRIMARY.color(), fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun JournalCommentSkeleton() {
    val alpha by rememberInfiniteTransition(label = "shimmer").animateFloat(
        initialValue = 0.08f,
        targetValue = 0.16f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "shimmerAlpha",
    )
    Column(
        modifier = Modifier
            .padding(end = 12.dp, top = 4.dp, bottom = 20.dp)
            .semantics { contentDescription = "AI 한마디를 만드는 중" },
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        listOf(1f, 0.7f).forEach { ratio ->
            Box(
                Modifier
                    .fillMaxWidth(ratio)
                    .height(14.dp)
                    .clip(CircleShape)
                    .background(MPAColor.AI_ACCENT.color().copy(alpha = alpha)),
            )
        }
    }
}

/** Fades the comment in word by word right after it is generated. */
@Composable
private fun JournalCommentText(text: String, revealsByWord: Boolean) {
    val words = remember(text) { text.split(" ") }
    var visibleWords by remember(text) { mutableIntStateOf(if (revealsByWord) 0 else Int.MAX_VALUE) }
    LaunchedEffect(text, revealsByWord) {
        if (!revealsByWord) {
            visibleWords = Int.MAX_VALUE
            return@LaunchedEffect
        }
        for (count in 1..words.size) {
            delay(60)
            visibleWords = count
        }
    }
    val color = MPAColor.TEXT_PRIMARY.color()
    // Hidden words keep their space so the lines do not reflow while revealing.
    val annotated = buildAnnotatedString {
        words.forEachIndexed { index, word ->
            withStyle(SpanStyle(color = if (index < visibleWords) color else Color.Transparent)) {
                append(if (index == 0) word else " $word")
            }
        }
    }
    Text(
        text = annotated,
        modifier = Modifier
            .padding(end = 12.dp)
            .semantics { contentDescription = text },
        fontSize = BODY_SIZE.sp,
        lineHeight = 28.sp,
    )
}

@Composable
private fun JournalCommentFooter(comment: AIText, actions: JournalDetailActions) {
    val view = LocalView.current
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = comment.engine.sourceLabel,
            modifier = Modifier.weight(1f),
            fontSize = 13.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
        listOf(
            Triple(AIFeedback.HELPFUL, R.drawable.ic_thumb_up to R.drawable.ic_thumb_up_filled, "도움이 됐어요"),
            Triple(AIFeedback.NOT_HELPFUL, R.drawable.ic_thumb_down to R.drawable.ic_thumb_down_filled, "도움이 안 됐어요"),
        ).forEach { (feedback, icons, label) ->
            val isSelected = comment.feedback == feedback
            IconButton(
                onClick = {
                    view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                    actions.onFeedback(feedback)
                },
                modifier = Modifier
                    .size(ACTION_SIZE)
                    .semantics { selected = isSelected },
            ) {
                Icon(
                    imageVector = ImageVector.vectorResource(if (isSelected) icons.second else icons.first),
                    contentDescription = label,
                    tint = if (isSelected) MPAColor.AI_ACCENT.color() else MPAColor.TEXT_SECONDARY.color(),
                )
            }
        }
        IconButton(onClick = actions.onRegenerateComment, modifier = Modifier.size(ACTION_SIZE)) {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_refresh),
                contentDescription = "다시 생성",
                tint = MPAColor.TEXT_SECONDARY.color(),
            )
        }
    }
}

// ---- Help resources ----

/** Replaces the AI comment when the entry reads as a crisis. Always expanded, no ✦ or feedback. */
@Composable
internal fun JournalHelpResourceCard(onCall: () -> Unit, onOpenResources: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CARD_RADIUS))
            .background(MPAColor.SURFACE.color())
            .border(1.dp, MPAColor.HAIRLINE.color(), RoundedCornerShape(CARD_RADIUS))
            .padding(GUTTER),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = "마음이 많이 무거운 날이었나 봐요",
            fontSize = 17.sp,
            fontWeight = FontWeight.Bold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Text(
            text = "혼자 견디지 않아도 괜찮아요. 지금 이야기를 들어줄 곳이 있어요.",
            fontSize = 15.sp,
            lineHeight = 22.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
        FlowRow(
            modifier = Modifier.padding(top = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Button(
                onClick = onCall,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MPAColor.BRAND_PRIMARY.color(),
                    contentColor = MPAColor.BRAND_ON_PRIMARY.color(),
                ),
            ) { Text("109 자살예방상담전화") }
            OutlinedButton(onClick = onOpenResources) {
                Text("다른 상담 창구", color = MPAColor.BRAND_PRIMARY.color())
            }
        }
    }
}

// ---- Keyword sheet ----

@Composable
private fun JournalKeywordSheet(
    summary: JournalKeywordSummary,
    currentJournalId: String?,
    onDismiss: () -> Unit,
    onOpenPrinciple: () -> Unit,
    onOpenEntry: (Journal) -> Unit,
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false),
        containerColor = MPAColor.CONTAINER.color(),
        scrimColor = MPAColor.SCRIM.color(),
    ) {
        JournalKeywordSheetContent(summary, currentJournalId, onOpenPrinciple, onOpenEntry)
    }
}

@Composable
private fun JournalKeywordSheetContent(
    summary: JournalKeywordSummary,
    currentJournalId: String?,
    onOpenPrinciple: () -> Unit,
    onOpenEntry: (Journal) -> Unit,
) {
    Column {
        Row(
            modifier = Modifier.padding(start = 24.dp, end = 24.dp, top = 8.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(
                Modifier
                    .padding(top = 6.dp)
                    .size(22.dp)
                    .clip(CircleShape)
                    .background(principleStageColor(summary.stage)),
            )
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = summary.name,
                    modifier = Modifier.semantics { heading() },
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Bold,
                    color = MPAColor.TEXT_PRIMARY.color(),
                )
                Text(
                    text = "${summary.entries.size}개의 일기에서 발견 · 처음 ${JournalDetailViewModel.shortDate(summary.firstSeen)}",
                    fontSize = 15.sp,
                    color = MPAColor.TEXT_SECONDARY.color(),
                )
                if (summary.isPrinciple) {
                    Text(
                        text = "원칙에서 자세히 보기 →",
                        modifier = Modifier
                            .heightIn(min = ACTION_SIZE)
                            .clickable(role = Role.Button, onClick = onOpenPrinciple)
                            .padding(vertical = 12.dp),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MPAColor.BRAND_PRIMARY.color(),
                    )
                } else {
                    Text(
                        text = "지금은 원칙 순위 밖이에요",
                        modifier = Modifier.padding(vertical = 12.dp),
                        fontSize = 15.sp,
                        color = MPAColor.TEXT_SECONDARY.color(),
                    )
                }
            }
        }
        HorizontalDivider(modifier = Modifier.padding(horizontal = 24.dp), color = MPAColor.HAIRLINE.color())
        LazyColumn {
            items(summary.entries, key = { it.id.toString() }) { entry ->
                val isCurrent = entry.id.toString() == currentJournalId
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(SHEET_ROW_HEIGHT)
                        .background(if (isCurrent) MPAColor.AI_TINT.color() else Color.Transparent)
                        .then(if (isCurrent) Modifier else Modifier.clickable { onOpenEntry(entry) })
                        .padding(horizontal = 24.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Text(
                        text = JournalDetailViewModel.shortDate(entry.day),
                        modifier = Modifier.widthIn(min = 64.dp),
                        fontSize = 15.sp,
                        color = MPAColor.TEXT_SECONDARY.color(),
                    )
                    Text(
                        text = entry.displayTitle,
                        modifier = Modifier.weight(1f),
                        fontSize = 16.sp,
                        fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.Normal,
                        color = MPAColor.TEXT_PRIMARY.color(),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    if (isCurrent) {
                        Text(
                            text = "지금 보는 일기",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MPAColor.AI_ACCENT.color(),
                        )
                    }
                }
            }
        }
    }
}

// ---- Date picker ----

@Composable
private fun JournalDetailDatePicker(initialDay: LocalDate, onConfirm: (LocalDate) -> Unit, onDismiss: () -> Unit) {
    val todayMillis = LocalDate.now().atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
    val pickerState = rememberDatePickerState(
        initialSelectedDateMillis = initialDay.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
        selectableDates = object : SelectableDates {
            // Entries can only be written for past days.
            override fun isSelectableDate(utcTimeMillis: Long) = utcTimeMillis <= todayMillis
            override fun isSelectableYear(year: Int) = year <= LocalDate.now().year
        },
    )
    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = {
                val millis = pickerState.selectedDateMillis ?: return@TextButton onDismiss()
                onConfirm(JavaInstant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate())
            }) { Text("확인") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("취소") } },
    ) {
        DatePicker(state = pickerState)
    }
}

// ---- Preview ----

private val previewComment = AIText(
    text = "듣는 쪽을 택하자 문제의 진짜 모양이 보였네요. 다음 회의에는 첫 질문 하나를 미리 적어 가 보는 건 어때요?",
    engine = AIEngine.GEMINI_NANO,
    generatedAt = Instant.parse("2026-10-27T12:53:00Z"),
)

private fun previewState(
    journal: Journal = Journal.sample,
    isCommentExpanded: Boolean = false,
    presentedKeyword: String? = null,
): JournalDetailUiState = JournalDetailUiState(
    journal = journal,
    allJournals = listOf(journal) + JournalSamples.detailKeyword,
    keywordStages = mapOf("경청" to 1, "솔직함" to 2),
    isCommentExpanded = isCommentExpanded,
    commentPhase = journal.aiComment?.let { JournalCommentPhase.Loaded(it) } ?: JournalCommentPhase.Idle,
    presentedKeyword = presentedKeyword,
)

private val PREVIEW_ZONE: ZoneId = ZoneId.of("Asia/Seoul")

@Preview(name = "detail", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalDetailPreview() {
    MPA_AndroidTheme {
        JournalDetailContent(previewState(), JournalDetailActions(), zone = PREVIEW_ZONE)
    }
}

/** The sheet content on its own, since previews do not render ModalBottomSheet's window. */
@Preview(name = "upperChipTapped", showBackground = true, widthDp = 412, heightDp = 540)
@Composable
private fun JournalDetailUpperChipTappedPreview() {
    MPA_AndroidTheme {
        val state = previewState(presentedKeyword = "경청")
        Box(Modifier.background(MPAColor.CONTAINER.color())) {
            JournalKeywordSheetContent(
                summary = state.presentedSummary!!,
                currentJournalId = state.journal?.id?.toString(),
                onOpenPrinciple = {},
                onOpenEntry = {},
            )
        }
    }
}

@Preview(name = "aiCommentBelow", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalDetailAICommentBelowPreview() {
    MPA_AndroidTheme {
        JournalDetailContent(
            state = previewState(journal = Journal.sample.copy(aiComment = previewComment), isCommentExpanded = true),
            actions = JournalDetailActions(),
            startsAtBottom = true,
            zone = PREVIEW_ZONE,
        )
    }
}

@Preview(name = "tablet-detail", showBackground = true, widthDp = 1194, heightDp = 834)
@Composable
private fun JournalDetailTabletPreview() {
    MPA_AndroidTheme {
        JournalDetailContent(previewState(), JournalDetailActions(), zone = PREVIEW_ZONE)
    }
}
