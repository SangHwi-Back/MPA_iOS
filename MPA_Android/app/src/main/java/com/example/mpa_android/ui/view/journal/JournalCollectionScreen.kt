// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.mpa_android.ui.view.journal

import android.content.Context
import android.view.accessibility.AccessibilityManager
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.mpa_android.R
import com.example.mpa_android.TopAppBarModel
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalSamples
import com.example.mpa_android.model.keywordStages
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.ui.theme.MPA_AndroidTheme
import com.example.mpa_android.viewmodel.JournalViewModel

/**
 * Entries that carry one keyword (Part A 3.9 "키워드로 모아 보기"). No search, toggle or calendar:
 * only the month sections of the list, with the same swipe delete and undo snackbar.
 */
@Composable
fun JournalCollectionScreen(
    viewModel: JournalViewModel,
    keyword: String,
    onBack: () -> Unit,
    onOpenEntry: (Journal) -> Unit,
    onEditEntry: (Journal) -> Unit,
    dynamicTopAppBar: (model: TopAppBarModel) -> Unit,
) {
    val journals by viewModel.visibleJournals.collectAsState()
    val pendingDeletion by viewModel.pendingDeletion.collectAsState()

    DisposableEffect(Unit) { onDispose { viewModel.commitDeletion() } }

    LaunchedEffect(keyword) {
        dynamicTopAppBar(TopAppBarModel(
            title = keyword,
            scrollBehavior = { TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState()) },
            leadingSection = {
                IconButton(onClick = onBack) {
                    Icon(
                        imageVector = ImageVector.vectorResource(R.drawable.ic_arrow_back),
                        contentDescription = "뒤로",
                        tint = MPAColor.TEXT_PRIMARY.color(),
                    )
                }
            },
            trailingSection = {},
        ))
    }

    JournalCollectionContent(
        journals = journals,
        keyword = keyword,
        pendingDeletion = pendingDeletion,
        keywordStages = remember(journals) { journals.keywordStages() },
        actions = JournalActions(
            onOpenEntry = onOpenEntry,
            onEditEntry = onEditEntry,
            onDelete = viewModel::deleteJournal,
            onUndoDelete = viewModel::undoDeletion,
            onCommitDelete = viewModel::commitDeletion,
        ),
    )
}

@Composable
private fun JournalCollectionContent(
    journals: List<Journal>,
    keyword: String,
    pendingDeletion: Journal?,
    keywordStages: Map<String, Int>,
    actions: JournalActions,
) {
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }
    val entries = remember(journals, keyword) {
        journals.filter { journal -> journal.visibleKeywords.any { it.name == keyword } }
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

    Box(modifier = Modifier
        .fillMaxSize()
        .background(MPAColor.CANVAS.color())) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 96.dp),
        ) {
            journalListItems(entries, keywordStages, actions)
        }
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(16.dp),
        )
    }
}

// ---- Previews ----

@Preview(name = "listSwipe", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun JournalCollectionListSwipePreview() {
    MPA_AndroidTheme {
        JournalCollectionContent(
            journals = JournalSamples.list,
            keyword = "경청",
            pendingDeletion = null,
            keywordStages = mapOf("휴식" to 0, "경청" to 1, "솔직함" to 2, "꾸준함" to 3, "감사" to 4),
            actions = JournalActions(),
        )
    }
}
