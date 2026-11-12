package com.example.mpa_android.ui.view

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.mpa_android.*
import com.example.mpa_android.ui.view.home.HomeActions
import com.example.mpa_android.ui.view.home.HomeScreen
import com.example.mpa_android.ui.view.journal.JournalScreen
import com.example.mpa_android.ui.view.principle.PrincipleScreen
import com.example.mpa_android.ui.view.settings.SettingsScreen
import com.example.mpa_android.viewmodel.JournalViewModel
import com.example.mpa_android.viewmodel.SettingsViewModel
import java.time.LocalDate

data class TabViewContentsModel(
    val destination: TabDestination,
    val selectTab: (TabDestination) -> Unit,
    val onDrawTopAppBar: (TopAppBarModel) -> Unit,
    val openEditor: (LocalDate?, String?) -> Unit,
)

@Composable
fun TabViewContents(
    navController: NavController,
    model: TabViewContentsModel
) {
    val settingsViewModel: SettingsViewModel = hiltViewModel()
    val journalViewModel: JournalViewModel = hiltViewModel()
    val settingsState by settingsViewModel.uiState.collectAsState()
    val globalModel = LocalAppGlobalModel.current

    when (model.destination) {
        TabDestination.TODAY -> HomeScreen(
            aiConnection = settingsState.aiConnection,
            actions = HomeActions(
                onWrite = { date, prompt -> model.openEditor(date, prompt) },
                onOpenEntry = { navController.navigate("$JOURNAL_DETAIL_ROUTE/${it.id}") },
                onOpenPrinciples = { model.selectTab(TabDestination.PRINCIPAL) },
                onOpenJournal = { model.selectTab(TabDestination.JOURNAL) },
                onConnectKey = { navController.navigate(SETTINGS_AI_CONNECTION_ROUTE) },
            ),
            dynamicTopAppBar = { model.onDrawTopAppBar(it) },
            onFabExpandedChange = { globalModel.isHomeFabExpanded = it },
        )
        TabDestination.JOURNAL -> JournalScreen(
            viewModel = journalViewModel,
            onWrite = { date -> navController.navigate("$JOURNAL_EDITOR_ROUTE?$JOURNAL_EDITOR_DATE_ARG=$date") },
            onOpenEntry = { navController.navigate("$JOURNAL_DETAIL_ROUTE/${it.id}") },
            onSearchActiveChange = { globalModel.isJournalSearchActive = it },
            scrollToTopSignal = globalModel.journalScrollToTopSignal,
            dynamicTopAppBar = { model.onDrawTopAppBar(it) },
        )
        TabDestination.PRINCIPAL -> PrincipleScreen(
            dynamicTopAppBar = { model.onDrawTopAppBar(it) },
        )
        TabDestination.SETTINGS -> SettingsScreen(
            viewModel = settingsViewModel,
            onOpenAIConnection = { navController.navigate(SETTINGS_AI_CONNECTION_ROUTE) },
            dynamicTopAppBar = { model.onDrawTopAppBar(it) },
        )
    }
}