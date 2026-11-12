package com.example.mpa_android

import android.os.Bundle
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.ui.theme.MPA_AndroidTheme
import com.example.mpa_android.ui.view.WriteJournalFloatingActionButton
import com.example.mpa_android.ui.view.home.homeFabLabel
import com.example.mpa_android.model.HomeAIStatus
import android.net.Uri
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.platform.LocalLayoutDirection
import com.example.mpa_android.ui.view.TabViewContents
import com.example.mpa_android.ui.view.TabViewContentsModel
import com.example.mpa_android.ui.view.journal.JournalDetailScreen
import com.example.mpa_android.ui.view.journal.JournalEditorScreen
import com.example.mpa_android.ui.view.settings.SettingsAIConnectionDetailScreen
import com.example.mpa_android.viewmodel.JournalDetailViewModel
import com.example.mpa_android.viewmodel.JournalViewModel
import com.example.mpa_android.viewmodel.SettingsViewModel
import dagger.hilt.android.AndroidEntryPoint
import java.time.LocalDate

const val JOURNAL_EDITOR_ROUTE = "journal-editor"
const val JOURNAL_EDITOR_DATE_ARG = "date"
const val JOURNAL_EDITOR_PROMPT_ARG = "prompt"
const val SETTINGS_AI_CONNECTION_ROUTE = "settings-ai-connection"
const val JOURNAL_DETAIL_ROUTE = "journal-detail"
const val JOURNAL_DETAIL_PATTERN = "$JOURNAL_DETAIL_ROUTE/{${JournalDetailViewModel.ARG_JOURNAL_ID}}"

val LocalAppGlobalModel = staticCompositionLocalOf {
    GlobalModel()
}

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MPA_AndroidTheme {
                App()
            }
        }
    }
}

enum class TabDestination(
    val route: String,
    val label: String,
    val contentDescription: String
) {
    TODAY("home-today", "오늘", "탭, 오늘"),
    JOURNAL("home-journal", "기록", "탭, 기록"),
    PRINCIPAL("home-principal", "원칙", "탭, 원칙"),
    SETTINGS("home-settings", "설정", "탭, 설정")
}

@Composable
fun TabDestination.icon(isSelected: Boolean): ImageVector = ImageVector.vectorResource(
    when (this) {
        TabDestination.TODAY ->
            if (isSelected)
                R.drawable.ic_tab_today_selected
            else
                R.drawable.ic_tab_today

        TabDestination.JOURNAL ->
            if (isSelected)
                R.drawable.ic_tab_journal_selected
            else
                R.drawable.ic_tab_journal

        TabDestination.PRINCIPAL ->
            if (isSelected)
                R.drawable.ic_tab_principles_selected
            else
                R.drawable.ic_tab_principles

        TabDestination.SETTINGS ->
            if (isSelected)
                R.drawable.ic_tab_settings_selected
            else
                R.drawable.ic_tab_settings
    }
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun App() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val startDestination = TabDestination.TODAY
    // Shared across tabs and the editor so a journal added from the editor shows up
    // in the Journal tab immediately (there is no server/DB yet to re-fetch from).
    val journalViewModel: JournalViewModel = hiltViewModel()
    // Shared by the settings list and the AI connection screen.
    val settingsViewModel: SettingsViewModel = hiltViewModel()
    val currentRoute = navBackStackEntry?.destination?.route
    val journals by journalViewModel.visibleJournals.collectAsState()
    val settingsState by settingsViewModel.uiState.collectAsState()
    // No AI: the 원칙 tab is hidden and the app becomes a plain diary (Home 3.15).
    val isAIAvailable = HomeAIStatus.from(settingsState.aiConnection).isAvailable
    val visibleTabs = TabDestination.entries.filter { isAIAvailable || it != TabDestination.PRINCIPAL }

    val globalModel = remember { GlobalModel(isHomeFabExpanded = true) }

    var topAppBarModel by remember { mutableStateOf(TopAppBarModel(
        "",
        null,
        { TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState()) },
        { },
        { }))
    }

    val scrollBehavior = topAppBarModel.scrollBehavior()

    fun openEditor(date: LocalDate? = null, prompt: String? = null) {
        val query = buildList {
            date?.let { add("$JOURNAL_EDITOR_DATE_ARG=$it") }
            prompt?.let { add("$JOURNAL_EDITOR_PROMPT_ARG=${Uri.encode(it)}") }
        }.joinToString("&")
        navController.navigate(if (query.isEmpty()) JOURNAL_EDITOR_ROUTE else "$JOURNAL_EDITOR_ROUTE?$query")
    }

    fun selectTab(tab: TabDestination) {
        navController.navigate(tab.route) {
            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
            launchSingleTop = true
            restoreState = true
        }
    }

    fun dynamicTopAppBar(model: TopAppBarModel) {
        topAppBarModel = model
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        // The expanded search screen extends its background under the status bar.
        containerColor = if (globalModel.isJournalSearchActive) MPAColor.CONTAINER.color() else MPAColor.CANVAS.color(),
        topBar = {
            // The journal detail draws its own app bar.
            if (currentRoute != null &&
                currentRoute != JOURNAL_DETAIL_PATTERN &&
                !currentRoute.contains(JOURNAL_EDITOR_ROUTE)) {

                MPATopAppBar(topAppBarModel, scrollBehavior)
            }
        },
        bottomBar = {
            if (
                !globalModel.isJournalSearchActive &&
                currentRoute != SETTINGS_AI_CONNECTION_ROUTE &&
                currentRoute != JOURNAL_DETAIL_PATTERN
            ) {
                NavigationBar(
                    containerColor = MPAColor.CONTAINER.color(),
                    tonalElevation = 0.dp,
                    windowInsets = NavigationBarDefaults.windowInsets,
                ) {
                    visibleTabs.forEach { destinations ->
                        val isSelected = currentRoute == destinations.route
                        NavigationBarItem(
                            selected = isSelected,
                            colors = NavigationBarItemDefaults.colors(
                                indicatorColor = MPAColor.BRAND_CONTAINER.color(),
                                selectedTextColor = MPAColor.TEXT_PRIMARY.color(),
                                unselectedTextColor = MPAColor.TEXT_PRIMARY.color(),
                            ),
                            onClick = {
                                if (isSelected && destinations == TabDestination.JOURNAL) {
                                    globalModel.journalScrollToTopSignal += 1
                                }
                                navController.navigate(destinations.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            label = {
                                Text(
                                    text = destinations.label,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis
                                )
                            },
                            icon = {
                                Icon(
                                    imageVector = destinations.icon(isSelected),
                                    contentDescription = destinations.contentDescription,
                                    tint = Color.Unspecified
                                )
                            },
                        )
                    }
                }
            }
        },
        floatingActionButton = {
            // The 기록 tab places its own FAB so it can sit above the undo snackbar.
            if (
                currentRoute != TabDestination.JOURNAL.route &&
                currentRoute != TabDestination.SETTINGS.route &&
                currentRoute != SETTINGS_AI_CONNECTION_ROUTE
            ) {
                val isHome = currentRoute == TabDestination.TODAY.route
                WriteJournalFloatingActionButton(
                    label = if (isHome) homeFabLabel(journals) else "쓰기",
                    isEmphasized = isHome && journals.isEmpty(),
                    expanded = !isHome || globalModel.isHomeFabExpanded,
                    // An existing entry for today should open in edit mode; the editor cannot load one yet.
                    onClick = { openEditor() },
                )
            }
        },
        content = { innerPadding ->
            globalModel.localInnerPadding = innerPadding

            val navPadding = if (currentRoute == JOURNAL_DETAIL_PATTERN || currentRoute?.contains(JOURNAL_EDITOR_ROUTE) == true) {
                PaddingValues(
                    start = innerPadding.calculateStartPadding(LocalLayoutDirection.current),
                    end = innerPadding.calculateEndPadding(LocalLayoutDirection.current),
                    bottom = innerPadding.calculateBottomPadding(),
                )
            } else innerPadding

            CompositionLocalProvider(LocalAppGlobalModel provides globalModel) {
                NavHost(
                    navController,
                    modifier = Modifier.padding(navPadding),
                    startDestination = startDestination.route
                ) {
                    TabDestination.entries.forEach { destination ->
                        composable(destination.route) {
                            TabViewContents(
                                navController,
                                TabViewContentsModel(
                                destination = destination,
                                selectTab = { selectTab(it) },
                                onDrawTopAppBar = { dynamicTopAppBar(it) },
                                openEditor = { date, prompt -> openEditor(date, prompt) }
                            ))
                        }
                    }
                    composable(JOURNAL_DETAIL_PATTERN) {
                        JournalDetailScreen(
                            onBack = { navController.popBackStack() },
                            // TODO: JournalEditorScreen cannot open an existing entry yet (Part C, 상세에서 편집).
                            onEdit = {},
                            onDelete = { journal ->
                                // Back to the list first, then the undo snackbar (Part A 3.8).
                                navController.popBackStack(TabDestination.JOURNAL.route, inclusive = false)
                                journalViewModel.deleteJournal(journal)
                            },
                            onOpenEntry = { navController.navigate("$JOURNAL_DETAIL_ROUTE/${it.id}") },
                            onOpenPrinciple = {
                                navController.navigate(TabDestination.PRINCIPAL.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                }
                            },
                        )
                    }
                    composable(SETTINGS_AI_CONNECTION_ROUTE) {
                        SettingsAIConnectionDetailScreen(
                            viewModel = settingsViewModel,
                            onBack = { navController.popBackStack() },
                        )
                    }
                    composable(
                        route = "$JOURNAL_EDITOR_ROUTE?$JOURNAL_EDITOR_DATE_ARG={$JOURNAL_EDITOR_DATE_ARG}" +
                                "&$JOURNAL_EDITOR_PROMPT_ARG={$JOURNAL_EDITOR_PROMPT_ARG}",
                        arguments = listOf(
                            navArgument(JOURNAL_EDITOR_DATE_ARG) {
                                type = NavType.StringType
                                nullable = true
                                defaultValue = null
                            },
                            navArgument(JOURNAL_EDITOR_PROMPT_ARG) {
                                type = NavType.StringType
                                nullable = true
                                defaultValue = null
                            },
                        ),
                        // Opens as a full-screen modal sliding up from the bottom, and back down on close.
                        enterTransition = { slideInVertically(initialOffsetY = { it }) },
                        popExitTransition = { slideOutVertically(targetOffsetY = { it }) },
                    ) { entry ->
                        JournalEditorScreen(
                            viewModel = journalViewModel,
                            initialDate = entry.arguments?.getString(JOURNAL_EDITOR_DATE_ARG)?.let(LocalDate::parse),
                            initialPrompt = entry.arguments?.getString(JOURNAL_EDITOR_PROMPT_ARG),
                            onClose = { navController.popBackStack() },
                        )
                    }
                }
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MPATopAppBar(
    model: TopAppBarModel,
    scrollBehavior: TopAppBarScrollBehavior
) {
    // No explicit title style: LargeTopAppBar swaps the expanded and collapsed styles itself.
    val title: @Composable () -> Unit = {
        Column {
            Text(model.title)
            if (model.subTitle != null) {
                Text(model.subTitle, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
    when (model.style) {
        TopAppBarStyle.SMALL -> TopAppBar(
            title = title,
            navigationIcon = model.leadingSection,
            actions = model.trailingSection,
            scrollBehavior = scrollBehavior
        )
        TopAppBarStyle.LARGE -> LargeTopAppBar(
            title = title,
            navigationIcon = model.leadingSection,
            actions = model.trailingSection,
            scrollBehavior = scrollBehavior
        )
    }
}

enum class TopAppBarStyle { SMALL, LARGE }

data class TopAppBarModel @OptIn(ExperimentalMaterial3Api::class) constructor(
    val title: String,
    val subTitle: String? = null,
    val scrollBehavior: @Composable () -> TopAppBarScrollBehavior,
    val leadingSection: @Composable () -> Unit,
    val trailingSection: @Composable RowScope.() -> Unit,
    val style: TopAppBarStyle = TopAppBarStyle.SMALL,
)

// Compose state holder so distant screens can read and write shared app state
// via LocalAppGlobalModel without threading it through every intermediate composable.
class GlobalModel(
    isJournalSearchActive: Boolean = false,
    isHomeFabExpanded: Boolean = false,
    journalScrollToTopSignal: Int = 0,
    localInnerPadding: PaddingValues = PaddingValues(0.dp),
) {
    var isJournalSearchActive by mutableStateOf(isJournalSearchActive)
    var isHomeFabExpanded by mutableStateOf(isHomeFabExpanded)
    var journalScrollToTopSignal by mutableIntStateOf(journalScrollToTopSignal)
    var localInnerPadding by mutableStateOf(localInnerPadding)
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    MPA_AndroidTheme {
        App()
    }
}