@file:OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)

package com.example.mpa_android.ui.view.journal

import android.content.Context
import android.content.Intent
import android.view.HapticFeedbackConstants
import android.view.accessibility.AccessibilityManager
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imeNestedScroll
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.SnackbarData
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.LocalSaveableStateRegistry
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.mpa_android.R
import com.example.mpa_android.TopAppBarModel
import com.example.mpa_android.model.AnalysisState
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalSamples
import com.example.mpa_android.model.PRINCIPLE_STAGE_COUNT
import com.example.mpa_android.model.keywordStages
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.ui.theme.MPA_AndroidTheme
import com.example.mpa_android.viewmodel.JournalViewModel
import com.example.mpa_android.viewmodel.JournalViewMode
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.temporal.WeekFields
import java.util.Locale
import kotlinx.coroutines.delay

private val KOREAN_WEEKDAYS = listOf("월", "화", "수", "목", "금", "토", "일")
private val DISABLED_ARROW = Color(0xFFC9C2B8)
private val PHOTO_PLACEHOLDER = Color(0xFFDCD5C9)
private val SNACKBAR_BACKGROUND = Color(0xFF322F2C)
private val SNACKBAR_ACTION = Color(0xFFAEB8F0)
private const val SEARCH_DEBOUNCE_MILLIS = 250L
private const val SNIPPET_VISIBLE_LENGTH = 40
private const val MAX_KEYWORD_SUGGESTIONS = 3
private const val SWIPE_DELETE_THRESHOLD = 0.4f

private fun DayOfWeek.korean(): String = KOREAN_WEEKDAYS[value - 1]

private fun YearMonth.koreanLabel(): String = "${year}년 ${monthValue}월"

private fun LocalDate.selectedDayLabel(): String = "${monthValue}월 ${dayOfMonth}일 ${dayOfWeek.korean()}요일"

private fun Journal.matches(query: String): Boolean =
    displayTitle.contains(query, ignoreCase = true) || body.contains(query, ignoreCase = true)

/** The preview text, cut to the sentence containing the match when the match is past the two visible lines. */
private fun Journal.searchSnippet(query: String): String {
    val text = previewText
    val match = text.indexOf(query, ignoreCase = true)
    if (match <= SNIPPET_VISIBLE_LENGTH) return text
    val sentenceBreak = text.lastIndexOf(". ", match)
    return "…" + text.substring(if (sentenceBreak >= 0) sentenceBreak + 2 else match)
}

private data class JournalActions(
    val onSetViewMode: (JournalViewMode) -> Unit = {},
    val onWrite: (LocalDate) -> Unit = {},
    val onOpenEntry: (Journal) -> Unit = {},
    val onEditEntry: (Journal) -> Unit = {},
    val onOpenKeyword: (String) -> Unit = {},
    val onDelete: (Journal) -> Unit = {},
    val onUndoDelete: () -> Unit = {},
    val onCommitDelete: () -> Unit = {},
    val onSubmitSearch: (String) -> Unit = {},
    val onRemoveRecentSearch: (String) -> Unit = {},
    val onSearchActiveChange: (Boolean) -> Unit = {},
)

@Composable
fun JournalScreen(
    viewModel: JournalViewModel = hiltViewModel(),
    onWrite: (LocalDate) -> Unit = {},
    onOpenEntry: (Journal) -> Unit = {},
    onEditEntry: (Journal) -> Unit = {},
    onOpenKeyword: (String) -> Unit = {},
    onSearchActiveChange: (Boolean) -> Unit = {},
    scrollToTopSignal: Int = 0,
    dynamicTopAppBar: (model: TopAppBarModel) -> Unit,
) {
    val journals by viewModel.visibleJournals.collectAsState()
    val viewMode by viewModel.viewMode.collectAsState()
    val recentSearches by viewModel.recentSearches.collectAsState()
    val pendingDeletion by viewModel.pendingDeletion.collectAsState()

    DisposableEffect(Unit) {
        onDispose {
            viewModel.commitDeletion()
            onSearchActiveChange(false)
        }
    }

    LaunchedEffect(Unit) {
        dynamicTopAppBar(TopAppBarModel(
            title = "기록",
            scrollBehavior = { TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState()) },
            leadingSection = {},
            trailingSection = { IconButton(onClick = {
                onWrite(LocalDate.now())
            }) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_add),
                    contentDescription = "기록 추가",
                    tint = MPAColor.TEXT_PRIMARY.color(),
                )
            } },
        ))
    }

    JournalContent(
        journals = journals,
        viewMode = viewMode,
        recentSearches = recentSearches,
        pendingDeletion = pendingDeletion,
        today = LocalDate.now(),
        keywordStages = remember(journals) { journals.keywordStages() },
        scrollToTopSignal = scrollToTopSignal,
        actions = JournalActions(
            onSetViewMode = viewModel::setViewMode,
            onWrite = onWrite,
            onOpenEntry = onOpenEntry,
            onEditEntry = onEditEntry,
            onOpenKeyword = onOpenKeyword,
            onDelete = viewModel::deleteJournal,
            onUndoDelete = viewModel::undoDeletion,
            onCommitDelete = viewModel::commitDeletion,
            onSubmitSearch = viewModel::addRecentSearch,
            onRemoveRecentSearch = viewModel::removeRecentSearch,
            onSearchActiveChange = onSearchActiveChange,
        ),
    )
}

@Composable
private fun JournalContent(
    journals: List<Journal>,
    viewMode: JournalViewMode,
    recentSearches: List<String>,
    pendingDeletion: Journal?,
    today: LocalDate,
    keywordStages: Map<String, Int>,
    actions: JournalActions,
    scrollToTopSignal: Int = 0,
    initialSelectedDate: LocalDate = today,
    initialSearchQuery: String = "",
) {
    val context = LocalContext.current
    val listState = rememberLazyListState()
    val snackbarHostState = remember { SnackbarHostState() }
    var isSearchExpanded by remember { mutableStateOf(initialSearchQuery.isNotEmpty()) }
    var query by remember { mutableStateOf(initialSearchQuery) }
    var selectedDate by remember { mutableStateOf(initialSelectedDate) }
    var displayedMonth by remember { mutableStateOf(YearMonth.from(initialSelectedDate)) }
    val isEmpty = journals.isEmpty()

    LaunchedEffect(scrollToTopSignal) {
        if (scrollToTopSignal > 0) listState.animateScrollToItem(0)
    }

    LaunchedEffect(pendingDeletion?.id) {
        val journal = pendingDeletion ?: return@LaunchedEffect
        val accessibility = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val result = snackbarHostState.showSnackbar(
            message = "‘${journal.displayTitle}’을 삭제했어요",
            actionLabel = "실행 취소",
            duration = if (accessibility.isTouchExplorationEnabled) SnackbarDuration.Indefinite else SnackbarDuration.Short,
        )
        if (result == SnackbarResult.ActionPerformed) actions.onUndoDelete() else actions.onCommitDelete()
    }

    fun setSearchExpanded(expanded: Boolean) {
        isSearchExpanded = expanded
        if (!expanded) query = ""
        actions.onSearchActiveChange(expanded)
    }

    if (isSearchExpanded) {
        JournalSearchScreen(
            query = query,
            onQueryChange = { query = it },
            onClose = { setSearchExpanded(false) },
            onSubmit = actions.onSubmitSearch,
        ) {
            JournalSearchContent(
                journals = journals,
                query = query,
                recentSearches = recentSearches,
                keywordStages = keywordStages,
                onSelectRecent = { query = it },
                actions = actions,
            )
        }
        return
    }

    Box(modifier = Modifier
        .fillMaxSize()
        .background(MPAColor.CANVAS.color())) {
        Column(modifier = Modifier.fillMaxSize()) {
            JournalSearchBar(
                enabled = !isEmpty,
                isScrolled = listState.canScrollBackward,
                onClick = { setSearchExpanded(true) },
            )

            if (isEmpty) {
                JournalEmptyState(
                    modifier = Modifier.weight(1f),
                    viewMode = viewMode,
                    listState = listState,
                    addAction = { actions.onWrite(today) }
                )
            } else {
                JournalBody(
                    journals = journals,
                    viewMode = viewMode,
                    today = today,
                    selectedDate = selectedDate,
                    displayedMonth = displayedMonth,
                    keywordStages = keywordStages,
                    listState = listState,
                    actions = actions,
                    onSelectViewMode = { mode ->
                        if (mode == JournalViewMode.CALENDAR) {
                            selectedDate = today
                            displayedMonth = YearMonth.from(today)
                        }
                        actions.onSetViewMode(mode)
                    },
                    onSelectDate = { selectedDate = it },
                    onShowMonth = { month ->
                        displayedMonth = month
                        selectedDate = journals.filter { YearMonth.from(it.day) == month }.maxOfOrNull { it.day }
                            ?: if (YearMonth.from(today) == month) today else month.atDay(1)
                    },
                )
            }
        }

        // The FAB sits above the snackbar, and the snackbar stays directly above the navigation bar.
        if (!isEmpty) {
            Column(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .fillMaxWidth(),
                horizontalAlignment = Alignment.End,
            ) {
                JournalFab(
                    isCalendar = viewMode == JournalViewMode.CALENDAR,
                    isScrollingDown = listState.lastScrolledForward,
                    onClick = { actions.onWrite(today) },
                    modifier = Modifier.padding(end = 16.dp, bottom = 16.dp),
                )
                SnackbarHost(snackbarHostState) { data ->
                    JournalUndoSnackbar(data)
                }
            }
        }
    }
}

@Composable
private fun JournalUndoSnackbar(data: SnackbarData) {
    Row(
        modifier = Modifier
            .padding(start = 16.dp, end = 16.dp, bottom = 16.dp)
            .fillMaxWidth()
            .height(48.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(SNACKBAR_BACKGROUND)
            .padding(start = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = data.visuals.message,
            modifier = Modifier.weight(1f),
            color = Color.White,
            fontSize = 15.sp,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = data.visuals.actionLabel.orEmpty(),
            modifier = Modifier
                .clickable { data.performAction() }
                .padding(horizontal = 16.dp, vertical = 14.dp),
            color = SNACKBAR_ACTION,
            fontSize = 15.sp,
            fontWeight = FontWeight.Bold,
        )
    }
}

@Composable
private fun JournalFab(
    isCalendar: Boolean,
    isScrollingDown: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    ExtendedFloatingActionButton(
        text = {
            Text(
                text = "첫 일기 쓰기",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
            )
        },
        icon = {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_edit),
                contentDescription = if (isCalendar) "쓰기" else null,
                tint = MPAColor.BRAND_ON_PRIMARY.color(),
            )
        },
        expanded = (!isCalendar && !isScrollingDown),
        onClick = onClick,
        modifier = modifier,
        containerColor =  MPAColor.BRAND_PRIMARY.color(),
        contentColor = MPAColor.BRAND_ON_PRIMARY.color(),
    )
}

@Composable
private fun JournalSearchBar(enabled: Boolean, isScrolled: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(if (isScrolled) MPAColor.CONTAINER.color() else Color.Transparent)
            .padding(horizontal = 16.dp, vertical = 8.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .alpha(if (enabled) 1f else 0.6f)
                .clip(CircleShape)
                .background(MPAColor.CONTAINER.color())
                .clickable(enabled = enabled, onClick = onClick)
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            JournalIcon(R.drawable.ic_search, null, MPAColor.TEXT_PRIMARY.color())
            Text("기록 검색", fontSize = 16.sp, color = MPAColor.TEXT_SECONDARY.color())
        }
    }
}

@Composable
private fun JournalSearchScreen(
    query: String,
    onQueryChange: (String) -> Unit,
    onClose: () -> Unit,
    onSubmit: (String) -> Unit,
    content: @Composable () -> Unit,
) {
    val focusRequester = remember { FocusRequester() }
    val textColor = MPAColor.TEXT_PRIMARY.color()

    BackHandler(onBack = onClose)
    LaunchedEffect(Unit) { focusRequester.requestFocus() }

    Column(modifier = Modifier
        .fillMaxSize()
        .background(MPAColor.CONTAINER.color())) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp)
                .padding(horizontal = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onClose) {
                JournalIcon(R.drawable.ic_arrow_back, "뒤로", textColor)
            }
            BasicTextField(
                value = query,
                onValueChange = onQueryChange,
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 8.dp)
                    .focusRequester(focusRequester),
                singleLine = true,
                textStyle = TextStyle(fontSize = 18.sp, color = textColor),
                cursorBrush = SolidColor(MPAColor.BRAND_PRIMARY.color()),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { onSubmit(query) }),
            )
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    JournalIcon(R.drawable.ic_close, "지우기", textColor)
                }
            }
        }
        HorizontalDivider(color = MPAColor.HAIRLINE.color())
        content()
    }
}

@Composable
private fun JournalIcon(resource: Int, description: String?, tint: Color, modifier: Modifier = Modifier) {
    Icon(
        imageVector = ImageVector.vectorResource(resource),
        contentDescription = description,
        tint = tint,
        modifier = modifier,
    )
}

// ---- Body ----

@Composable
private fun JournalBody(
    journals: List<Journal>,
    viewMode: JournalViewMode,
    today: LocalDate,
    selectedDate: LocalDate,
    displayedMonth: YearMonth,
    keywordStages: Map<String, Int>,
    listState: LazyListState,
    actions: JournalActions,
    onSelectViewMode: (JournalViewMode) -> Unit,
    onSelectDate: (LocalDate) -> Unit,
    onShowMonth: (YearMonth) -> Unit,
) {
    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 96.dp),
    ) {
        item(key = "mode") {
            JournalModeToggle(
                selected = viewMode,
                onSelect = onSelectViewMode,
                modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 12.dp),
            )
        }
        when (viewMode) {
            JournalViewMode.LIST -> journalListItems(journals, keywordStages, actions)
            JournalViewMode.CALENDAR -> item(key = "calendar") {
                Box(Modifier.animateItem()) {
                    JournalCalendar(
                        journals = journals,
                        today = today,
                        selectedDate = selectedDate,
                        displayedMonth = displayedMonth,
                        keywordStages = keywordStages,
                        actions = actions,
                        onSelectDate = onSelectDate,
                        onShowMonth = onShowMonth,
                    )
                }
            }
        }
    }
}

@Composable
private fun JournalModeToggle(
    selected: JournalViewMode,
    onSelect: (JournalViewMode) -> Unit,
    modifier: Modifier = Modifier,
) {
    val modes = listOf(JournalViewMode.LIST to "리스트", JournalViewMode.CALENDAR to "캘린더")
    SingleChoiceSegmentedButtonRow(modifier = modifier.fillMaxWidth()) {
        modes.forEachIndexed { index, (mode, label) ->
            SegmentedButton(
                selected = selected == mode,
                onClick = { onSelect(mode) },
                modifier = Modifier.height(42.dp),
                shape = SegmentedButtonDefaults.itemShape(index = index, count = modes.size),
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = MPAColor.BRAND_CONTAINER.color(),
                    activeContentColor = MPAColor.BRAND_ON_CONTAINER.color(),
                    activeBorderColor = MPAColor.TEXT_TERTIARY.color(),
                    inactiveContainerColor = Color.Transparent,
                    inactiveContentColor = MPAColor.TEXT_PRIMARY.color(),
                    inactiveBorderColor = MPAColor.TEXT_TERTIARY.color(),
                ),
                label = {
                    Text(label, fontWeight = if (selected == mode) FontWeight.Bold else FontWeight.Normal)
                },
            )
        }
    }
}

private fun LazyListScope.journalListItems(
    journals: List<Journal>,
    keywordStages: Map<String, Int>,
    actions: JournalActions,
) {
    val sections = journals.groupBy { YearMonth.from(it.day) }.toSortedMap(compareByDescending { it })
    sections.forEach { (month, entries) ->
        stickyHeader(key = month.toString()) {
            JournalMonthHeader(month = month, count = entries.size)
        }
        items(entries.sortedByDescending { it.day }, key = { it.id.toString() }) { entry ->
            Column(Modifier.animateItem()) {
                // Without this, a row restored by undo gets its saved "dismissed" state back and is deleted again.
                CompositionLocalProvider(LocalSaveableStateRegistry provides null) {
                    JournalSwipeRow(entry = entry, keywordStages = keywordStages, actions = actions)
                }
                HorizontalDivider(color = MPAColor.HAIRLINE.color())
            }
        }
    }
}

@Composable
private fun JournalMonthHeader(month: YearMonth, count: Int) {
    Column(modifier = Modifier
        .fillMaxWidth()
        .background(MPAColor.CANVAS.color())) {
        Row(
            modifier = Modifier.padding(start = 20.dp, top = 8.dp, bottom = 10.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = month.koreanLabel(),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Text(text = "${count}편", fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
        }
        HorizontalDivider(color = MPAColor.HAIRLINE.color())
    }
}

@Composable
private fun JournalSwipeRow(
    entry: Journal,
    keywordStages: Map<String, Int>,
    actions: JournalActions,
) {
    val view = LocalView.current
    val state = rememberSwipeToDismissBoxState(
        positionalThreshold = { totalDistance -> totalDistance * SWIPE_DELETE_THRESHOLD },
    )
    var isMenuOpen by remember { mutableStateOf(false) }

    LaunchedEffect(state.targetValue) {
        if (state.targetValue == SwipeToDismissBoxValue.EndToStart) {
            view.performHapticFeedback(HapticFeedbackConstants.GESTURE_THRESHOLD_ACTIVATE)
        }
    }

    SwipeToDismissBox(
        state = state,
        enableDismissFromStartToEnd = false,
        onDismiss = { actions.onDelete(entry) },
        backgroundContent = {
            val isPastThreshold = state.targetValue == SwipeToDismissBoxValue.EndToStart
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MPAColor.DANGER.color().copy(alpha = if (isPastThreshold) 1f else 0.7f))
                    .padding(end = 20.dp),
                horizontalArrangement = Arrangement.End,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                JournalIcon(R.drawable.ic_delete, null, Color.White)
                Spacer(Modifier.width(8.dp))
                Text("삭제", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }
        },
    ) {
        val isSwiping = state.dismissDirection == SwipeToDismissBoxValue.EndToStart
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    color = MPAColor.CANVAS.color(),
                    shape = RoundedCornerShape(
                        topEnd = if (isSwiping) 28.dp else 0.dp,
                        bottomEnd = if (isSwiping) 28.dp else 0.dp,
                    ),
                )
                .combinedClickable(
                    onClick = { actions.onOpenEntry(entry) },
                    onLongClick = { isMenuOpen = true },
                ),
        ) {
            JournalEntryRow(
                entry = entry,
                keywordStages = keywordStages,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 14.dp),
            )
            JournalEntryMenu(
                entry = entry,
                expanded = isMenuOpen,
                onDismiss = { isMenuOpen = false },
                actions = actions,
            )
        }
    }
}

@Composable
private fun JournalEntryMenu(
    entry: Journal,
    expanded: Boolean,
    onDismiss: () -> Unit,
    actions: JournalActions,
) {
    val context = LocalContext.current
    DropdownMenu(
        expanded = expanded,
        onDismissRequest = onDismiss,
        shape = RoundedCornerShape(16.dp),
        containerColor = MPAColor.CONTAINER.color(),
    ) {
        DropdownMenuItem(
            text = { Text("편집") },
            onClick = {
                onDismiss()
                actions.onEditEntry(entry)
            },
        )
        DropdownMenuItem(
            text = { Text("공유") },
            onClick = {
                onDismiss()
                val send = Intent(Intent.ACTION_SEND)
                    .setType("text/plain")
                    .putExtra(Intent.EXTRA_TEXT, "${entry.displayTitle}\n\n${entry.body}")
                context.startActivity(Intent.createChooser(send, null))
            },
        )
        DropdownMenuItem(
            text = { Text("삭제", color = MPAColor.DANGER.color()) },
            onClick = {
                onDismiss()
                actions.onDelete(entry)
            },
        )
    }
}

private enum class DateCaption { WEEKDAY, MONTH }

/** One journal item. Used by the list, the calendar's selected day, and search results. */
@Composable
private fun JournalEntryRow(
    entry: Journal,
    keywordStages: Map<String, Int>,
    modifier: Modifier = Modifier,
    caption: DateCaption = DateCaption.WEEKDAY,
    highlight: String? = null,
    bodyText: String = entry.previewText,
) {
    val highlightColor = MPAColor.HIGHLIGHT_SEARCH.color()
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Column(modifier = Modifier.width(40.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = entry.day.dayOfMonth.toString(),
                style = TextStyle(fontFamily = FontFamily.Serif),
                fontSize = 24.sp,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            Text(
                text = if (caption == DateCaption.WEEKDAY) entry.day.dayOfWeek.korean() else "${entry.day.monthValue}월",
                fontSize = 13.sp,
                color = MPAColor.TEXT_SECONDARY.color(),
            )
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = highlighted(entry.displayTitle, highlight, highlightColor),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.TEXT_PRIMARY.color(),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = highlighted(bodyText, highlight, highlightColor),
                fontSize = 14.sp,
                lineHeight = 21.sp,
                color = MPAColor.TEXT_SECONDARY.color(),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            JournalKeywordRow(entry = entry, keywordStages = keywordStages, emphasized = highlight)
        }

        entry.thumbnail?.let {
            JournalThumbnail(extraCount = entry.photos.size - 1)
        }
    }
}

private fun highlighted(text: String, highlight: String?, color: Color) = buildAnnotatedString {
    if (highlight.isNullOrEmpty()) {
        append(text)
        return@buildAnnotatedString
    }
    var start = 0
    while (true) {
        val match = text.indexOf(highlight, start, ignoreCase = true)
        if (match < 0) {
            append(text.substring(start))
            break
        }
        append(text.substring(start, match))
        withStyle(SpanStyle(background = color)) {
            append(text.substring(match, match + highlight.length))
        }
        start = match + highlight.length
    }
}

@Composable
private fun JournalKeywordRow(entry: Journal, keywordStages: Map<String, Int>, emphasized: String?) {
    val chips = entry.visibleKeywords.take(Journal.MAX_KEYWORDS_IN_LIST)
    when {
        entry.analysisState is AnalysisState.Analyzed && chips.isNotEmpty() -> Row(
            modifier = Modifier.padding(top = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            chips.forEach { keyword ->
                JournalKeywordChip(
                    name = keyword.name,
                    stage = keywordStages[keyword.name] ?: 0,
                    isEmphasized = keyword.name == emphasized,
                )
            }
        }
        // Analysis has not finished, so the chip area stays blank instead of collapsing.
        entry.analysisState is AnalysisState.NotAnalyzed || entry.analysisState is AnalysisState.Analyzing ->
            Spacer(Modifier.height(32.dp))
    }
}

@Composable
private fun principleColor(stage: Int): Color = listOf(
    MPAColor.PRINCIPLE_1,
    MPAColor.PRINCIPLE_2,
    MPAColor.PRINCIPLE_3,
    MPAColor.PRINCIPLE_4,
    MPAColor.PRINCIPLE_5,
)[stage.coerceIn(0, PRINCIPLE_STAGE_COUNT - 1)].color()

@Composable
private fun JournalKeywordChip(name: String, stage: Int, isEmphasized: Boolean) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(MPAColor.AI_TINT.color())
            .padding(horizontal = 10.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        Box(Modifier
            .size(7.dp)
            .clip(CircleShape)
            .background(principleColor(stage)))
        Text(
            text = name,
            fontSize = 13.sp,
            fontWeight = if (isEmphasized) FontWeight.Bold else FontWeight.Normal,
            color = MPAColor.AI_ACCENT.color(),
        )
    }
}

@Composable
private fun JournalThumbnail(extraCount: Int) {
    Box(
        modifier = Modifier
            .size(60.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(PHOTO_PLACEHOLDER),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_image_placeholder_glyph),
            contentDescription = null,
            tint = Color.Unspecified,
            modifier = Modifier.size(22.dp),
        )
        if (extraCount > 0) {
            Text(
                text = "+$extraCount",
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(4.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color.Black.copy(alpha = 0.55f))
                    .padding(horizontal = 6.dp, vertical = 2.dp),
                color = Color.White,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}

// ---- Search ----

@Composable
private fun JournalSearchContent(
    journals: List<Journal>,
    query: String,
    recentSearches: List<String>,
    keywordStages: Map<String, Int>,
    onSelectRecent: (String) -> Unit,
    actions: JournalActions,
) {
    var appliedQuery by remember { mutableStateOf(query) }
    LaunchedEffect(query) {
        if (query.isNotEmpty()) delay(SEARCH_DEBOUNCE_MILLIS)
        appliedQuery = query
    }

    val suggestions = remember(journals, appliedQuery) {
        if (appliedQuery.isEmpty()) {
            emptyList()
        } else {
            journals
                .flatMap { it.visibleKeywords }
                .filter { it.name.contains(appliedQuery, ignoreCase = true) }
                .groupingBy { it.name }
                .eachCount()
                .entries
                .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
                .take(MAX_KEYWORD_SUGGESTIONS)
        }
    }
    val results = remember(journals, appliedQuery) {
        if (appliedQuery.isEmpty()) emptyList() else journals.filter { it.matches(appliedQuery) }.sortedByDescending { it.day }
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .imeNestedScroll(),
        contentPadding = PaddingValues(top = 12.dp, bottom = 16.dp),
    ) {
        when {
            query.isEmpty() -> {
                if (recentSearches.isNotEmpty()) item { JournalSearchLabel("최근 검색") }
                items(recentSearches, key = { it }) { recent ->
                    JournalRecentSearchRow(recent, onSelect = onSelectRecent, onRemove = actions.onRemoveRecentSearch)
                }
            }
            appliedQuery.isEmpty() -> Unit
            suggestions.isEmpty() && results.isEmpty() -> item {
                JournalNoResults(appliedQuery)
            }
            else -> {
                if (suggestions.isNotEmpty()) item { JournalSearchLabel("키워드") }
                items(suggestions, key = { it.key }) { (name, count) ->
                    JournalKeywordSuggestionRow(
                        name = name,
                        count = count,
                        stage = keywordStages[name] ?: 0,
                        onClick = { actions.onOpenKeyword(name) },
                    )
                }
                if (results.isNotEmpty()) item { JournalSearchLabel("제목·본문 ${results.size}편") }
                results.forEachIndexed { index, entry ->
                    item(key = entry.id.toString()) {
                        if (index > 0) HorizontalDivider(color = MPAColor.HAIRLINE.color())
                        JournalEntryRow(
                            entry = entry,
                            keywordStages = keywordStages,
                            modifier = Modifier
                                .clickable { actions.onOpenEntry(entry) }
                                .padding(horizontal = 20.dp, vertical = 12.dp),
                            caption = DateCaption.MONTH,
                            highlight = appliedQuery,
                            bodyText = entry.searchSnippet(appliedQuery),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun JournalSearchLabel(text: String) {
    Text(
        text = text,
        modifier = Modifier.padding(start = 20.dp, top = 8.dp, bottom = 8.dp),
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold,
        color = MPAColor.TEXT_SECONDARY.color(),
    )
}

@Composable
private fun JournalRecentSearchRow(query: String, onSelect: (String) -> Unit, onRemove: (String) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSelect(query) }
            .padding(start = 20.dp, end = 8.dp)
            .height(48.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        JournalIcon(R.drawable.ic_schedule, null, MPAColor.TEXT_SECONDARY.color(), Modifier.size(20.dp))
        Text(query, modifier = Modifier.weight(1f), fontSize = 16.sp, color = MPAColor.TEXT_PRIMARY.color())
        IconButton(onClick = { onRemove(query) }) {
            JournalIcon(R.drawable.ic_close, "$query 삭제", MPAColor.TEXT_SECONDARY.color(), Modifier.size(18.dp))
        }
    }
}

@Composable
private fun JournalKeywordSuggestionRow(name: String, count: Int, stage: Int, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp)
            .height(56.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(Modifier
            .size(24.dp)
            .clip(CircleShape)
            .background(principleColor(stage)))
        Text(
            text = buildAnnotatedString {
                withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(name) }
                append(" 키워드로 모아 보기")
            },
            modifier = Modifier.weight(1f),
            fontSize = 16.sp,
            color = MPAColor.TEXT_PRIMARY.color(),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(text = "${count}편", fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
        JournalIcon(R.drawable.ic_north_east, null, MPAColor.TEXT_SECONDARY.color(), Modifier.size(20.dp))
    }
}

@Composable
private fun JournalNoResults(query: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        JournalIcon(R.drawable.ic_search, null, MPAColor.TEXT_TERTIARY.color(), Modifier.size(28.dp))
        Text("‘$query’에 맞는 기록이 없어요", fontSize = 15.sp, color = MPAColor.TEXT_SECONDARY.color())
    }
}

// ---- Calendar ----

@Composable
private fun JournalCalendar(
    journals: List<Journal>,
    today: LocalDate,
    selectedDate: LocalDate,
    displayedMonth: YearMonth,
    keywordStages: Map<String, Int>,
    actions: JournalActions,
    onSelectDate: (LocalDate) -> Unit,
    onShowMonth: (YearMonth) -> Unit,
) {
    val latestMonth = YearMonth.from(today)
    val earliestMonth = journals.minOfOrNull { YearMonth.from(it.day) } ?: latestMonth
    val entriesByDay = remember(journals) { journals.groupBy { it.day } }
    var isPickingMonth by remember { mutableStateOf(false) }
    val monthEntries = journals.count { YearMonth.from(it.day) == displayedMonth }
    val selectedEntries = entriesByDay[selectedDate].orEmpty()

    fun moveMonth(offset: Long) {
        val target = displayedMonth.plusMonths(offset)
        if (target in earliestMonth..latestMonth) onShowMonth(target)
    }

    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        JournalMonthBar(
            month = displayedMonth,
            isPickingMonth = isPickingMonth,
            canGoPrevious = displayedMonth > earliestMonth,
            canGoNext = displayedMonth < latestMonth,
            onToggleMonthPicker = { isPickingMonth = !isPickingMonth },
            onMove = ::moveMonth,
        )

        if (isPickingMonth) {
            JournalYearMonthGrid(
                displayedMonth = displayedMonth,
                earliestMonth = earliestMonth,
                latestMonth = latestMonth,
                onSelect = {
                    onShowMonth(it)
                    isPickingMonth = false
                },
            )
        } else {
            JournalMonthGrid(
                month = displayedMonth,
                today = today,
                selectedDate = selectedDate,
                entriesByDay = entriesByDay,
                onMove = ::moveMonth,
                onTapDay = { date ->
                    if (date == selectedDate && selectedEntries.size == 1) actions.onOpenEntry(selectedEntries.first())
                    onSelectDate(date)
                },
            )
        }

        HorizontalDivider(modifier = Modifier.padding(top = 8.dp), color = MPAColor.HAIRLINE.color())
        Spacer(Modifier.height(14.dp))

        if (monthEntries == 0) {
            JournalCalendarMessage("이 달의 기록이 없어요")
        } else {
            Text(
                text = selectedDate.selectedDayLabel(),
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = MPAColor.TEXT_SECONDARY.color(),
            )
            Spacer(Modifier.height(12.dp))
            if (selectedEntries.isEmpty()) {
                JournalCalendarMessage("이 날의 기록이 없어요")
                Text(
                    text = "이 날짜로 쓰기",
                    modifier = Modifier
                        .align(Alignment.CenterHorizontally)
                        .clickable { actions.onWrite(selectedDate) }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MPAColor.BRAND_PRIMARY.color(),
                )
            } else {
                selectedEntries.forEach { entry ->
                    JournalEntryRow(
                        entry = entry,
                        keywordStages = keywordStages,
                        modifier = Modifier
                            .clickable { actions.onOpenEntry(entry) }
                            .padding(bottom = 12.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun JournalCalendarMessage(text: String) {
    Text(
        text = text,
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        fontSize = 15.sp,
        color = MPAColor.TEXT_SECONDARY.color(),
        textAlign = TextAlign.Center,
    )
}

@Composable
private fun JournalMonthBar(
    month: YearMonth,
    isPickingMonth: Boolean,
    canGoPrevious: Boolean,
    canGoNext: Boolean,
    onToggleMonthPicker: () -> Unit,
    onMove: (Long) -> Unit,
) {
    Row(modifier = Modifier.height(39.dp), verticalAlignment = Alignment.CenterVertically) {
        Row(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight()
                .clickable(onClick = onToggleMonthPicker),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = month.koreanLabel(),
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            JournalIcon(
                resource = R.drawable.ic_expand_more,
                description = if (isPickingMonth) "달력으로 돌아가기" else "연·월 선택",
                tint = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.size(20.dp),
            )
        }
        JournalMonthArrow(R.drawable.ic_chevron_left, "이전 달", canGoPrevious) { onMove(-1) }
        JournalMonthArrow(R.drawable.ic_chevron_right, "다음 달", canGoNext) { onMove(1) }
    }
}

@Composable
private fun JournalMonthArrow(resource: Int, description: String, enabled: Boolean, onClick: () -> Unit) {
    IconButton(onClick = onClick, enabled = enabled, modifier = Modifier.requiredSize(48.dp)) {
        JournalIcon(resource, description, if (enabled) MPAColor.TEXT_PRIMARY.color() else DISABLED_ARROW)
    }
}

@Composable
private fun JournalYearMonthGrid(
    displayedMonth: YearMonth,
    earliestMonth: YearMonth,
    latestMonth: YearMonth,
    onSelect: (YearMonth) -> Unit,
) {
    var year by remember { mutableStateOf(displayedMonth.year) }
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            JournalMonthArrow(R.drawable.ic_chevron_left, "이전 해", year > earliestMonth.year) { year -= 1 }
            Text(
                text = "${year}년",
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Center,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
            JournalMonthArrow(R.drawable.ic_chevron_right, "다음 해", year < latestMonth.year) { year += 1 }
        }
        (1..12).chunked(4).forEach { months ->
            Row(modifier = Modifier.fillMaxWidth()) {
                months.forEach { value ->
                    val month = YearMonth.of(year, value)
                    val enabled = month in earliestMonth..latestMonth
                    val isSelected = month == displayedMonth
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp)
                            .clip(RoundedCornerShape(24.dp))
                            .background(if (isSelected) MPAColor.BRAND_PRIMARY.color() else Color.Transparent)
                            .clickable(enabled = enabled) { onSelect(month) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = "${value}월",
                            fontSize = 15.sp,
                            color = when {
                                isSelected -> MPAColor.BRAND_ON_PRIMARY.color()
                                enabled -> MPAColor.TEXT_PRIMARY.color()
                                else -> DISABLED_ARROW
                            },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun JournalMonthGrid(
    month: YearMonth,
    today: LocalDate,
    selectedDate: LocalDate,
    entriesByDay: Map<LocalDate, List<Journal>>,
    onMove: (Long) -> Unit,
    onTapDay: (LocalDate) -> Unit,
) {
    val firstDayOfWeek = WeekFields.of(Locale.getDefault()).firstDayOfWeek
    val weekdays = List(7) { firstDayOfWeek.plus(it.toLong()) }
    val leading = (month.atDay(1).dayOfWeek.value - firstDayOfWeek.value + 7) % 7
    val cells: List<LocalDate?> = List(leading) { null } + (1..month.lengthOfMonth()).map(month::atDay)
    var dragTotal by remember { mutableStateOf(0f) }
    val swipeThreshold = 120f

    Column(
        modifier = Modifier.pointerInput(month) {
            detectHorizontalDragGestures(
                onDragStart = { dragTotal = 0f },
                onDragEnd = {
                    if (dragTotal < -swipeThreshold) onMove(1)
                    if (dragTotal > swipeThreshold) onMove(-1)
                },
                onHorizontalDrag = { _, amount -> dragTotal += amount },
            )
        },
    ) {
        Row(modifier = Modifier.fillMaxWidth()) {
            weekdays.forEach { day ->
                Text(
                    text = day.korean(),
                    modifier = Modifier
                        .weight(1f)
                        .padding(vertical = 4.dp),
                    fontSize = 13.sp,
                    color = MPAColor.TEXT_SECONDARY.color(),
                    textAlign = TextAlign.Center,
                )
            }
        }
        cells.chunked(7).forEach { week ->
            Row(modifier = Modifier.fillMaxWidth()) {
                (week + List(7 - week.size) { null }).forEach { date ->
                    JournalCalendarDayCell(
                        date = date,
                        isToday = date == today,
                        isSelected = date == selectedDate,
                        isFuture = date != null && date > today,
                        hasEntry = date != null && !entriesByDay[date].isNullOrEmpty(),
                        onTap = onTapDay,
                    )
                }
            }
        }
    }
}

@Composable
private fun RowScope.JournalCalendarDayCell(
    date: LocalDate?,
    isToday: Boolean,
    isSelected: Boolean,
    isFuture: Boolean,
    hasEntry: Boolean,
    onTap: (LocalDate) -> Unit,
) {
    if (date == null) {
        Spacer(Modifier
            .weight(1f)
            .height(48.dp))
        return
    }
    val brand = MPAColor.BRAND_PRIMARY.color()
    val label = buildList {
        add("${date.monthValue}월 ${date.dayOfMonth}일")
        if (hasEntry) add("일기 있음")
        if (isSelected) add("선택됨")
    }.joinToString(", ")

    Column(
        modifier = Modifier
            .weight(1f)
            .height(48.dp)
            .clickable(enabled = !isFuture) { onTap(date) }
            .semantics { contentDescription = label },
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(if (isSelected) brand else Color.Transparent)
                .then(if (isToday && !isSelected) Modifier.border(1.5.dp, brand, CircleShape) else Modifier),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = date.dayOfMonth.toString(),
                fontSize = 15.sp,
                fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.Normal,
                color = when {
                    isSelected -> MPAColor.BRAND_ON_PRIMARY.color()
                    isFuture -> DISABLED_ARROW
                    isToday -> brand
                    else -> MPAColor.TEXT_PRIMARY.color()
                },
                modifier = Modifier.clearAndSetSemantics { },
            )
        }
        Spacer(Modifier.height(3.dp))
        Box(Modifier
            .size(5.dp)
            .clip(CircleShape)
            .background(if (hasEntry) brand else Color.Transparent))
    }
}

// ---- Empty ----

@Composable
private fun JournalEmptyState(
    modifier: Modifier = Modifier,
    viewMode: JournalViewMode,
    listState: LazyListState,
    addAction: () -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 168.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_empty_journal),
            contentDescription = null,
            tint = Color.Unspecified,
            modifier = Modifier.size(width = 170.dp, height = 130.dp),
        )
        Spacer(Modifier.height(16.dp))
        Text(
            text = "아직 기록이 없어요",
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = MPAColor.TEXT_PRIMARY.color(),
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = "첫 일기를 쓰면 여기에\n날짜별로 차곡차곡 모여요.",
            fontSize = 15.sp,
            lineHeight = 24.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(24.dp))
        JournalFab(
            isCalendar = viewMode == JournalViewMode.CALENDAR,
            isScrollingDown = listState.lastScrolledForward,
            onClick = addAction,
        )
    }
}

// ---- Previews ----

private val PREVIEW_TODAY = LocalDate.of(2026, 10, 30)
private val PREVIEW_SELECTED = LocalDate.of(2026, 10, 27)
private val PREVIEW_KEYWORD_STAGES = mapOf("휴식" to 0, "경청" to 1, "솔직함" to 2, "꾸준함" to 3, "감사" to 4)

@Composable
private fun JournalPreview(
    journals: List<Journal> = JournalSamples.list,
    viewMode: JournalViewMode = JournalViewMode.LIST,
    pendingDeletion: Journal? = null,
    searchQuery: String = "",
) {
    MPA_AndroidTheme {
        JournalContent(
            journals = journals,
            viewMode = viewMode,
            recentSearches = emptyList(),
            pendingDeletion = pendingDeletion,
            today = PREVIEW_TODAY,
            keywordStages = PREVIEW_KEYWORD_STAGES,
            actions = JournalActions(),
            initialSelectedDate = PREVIEW_SELECTED,
            initialSearchQuery = searchQuery,
        )
    }
}

@Preview(name = "listSegment", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalListSegmentPreview() = JournalPreview()

@Preview(name = "calendarSegment", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalCalendarSegmentPreview() =
    JournalPreview(journals = JournalSamples.calendar, viewMode = JournalViewMode.CALENDAR)

@Preview(name = "emptyJournals", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalEmptyJournalsPreview() = JournalPreview(journals = emptyList())

@Preview(name = "listSwipe", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalListSwipePreview() = JournalPreview(pendingDeletion = JournalSamples.list[1])

@Preview(name = "searching", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalSearchingPreview() = JournalPreview(journals = JournalSamples.search, searchQuery = "경청")
