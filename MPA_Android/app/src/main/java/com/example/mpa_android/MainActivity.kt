package com.example.mpa_android

import android.os.Bundle
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
import com.example.mpa_android.ui.view.home.HomeScreen
import com.example.mpa_android.ui.view.journal.JournalDetailScreen
import com.example.mpa_android.ui.view.journal.JournalEditorScreen
import com.example.mpa_android.ui.view.journal.JournalScreen
import com.example.mpa_android.ui.view.principle.PrincipleScreen
import com.example.mpa_android.ui.view.settings.SettingsAIConnectionDetailScreen
import com.example.mpa_android.ui.view.settings.SettingsScreen
import com.example.mpa_android.viewmodel.JournalDetailViewModel
import com.example.mpa_android.viewmodel.JournalViewModel
import com.example.mpa_android.viewmodel.SettingsViewModel
import dagger.hilt.android.AndroidEntryPoint
import java.time.LocalDate

private const val JOURNAL_EDITOR_ROUTE = "journal-editor"
private const val JOURNAL_EDITOR_DATE_ARG = "date"
private const val SETTINGS_AI_CONNECTION_ROUTE = "settings-ai-connection"
private const val JOURNAL_DETAIL_ROUTE = "journal-detail"
private const val JOURNAL_DETAIL_PATTERN = "$JOURNAL_DETAIL_ROUTE/{${JournalDetailViewModel.ARG_JOURNAL_ID}}"

val LocalInnerPadding = staticCompositionLocalOf {
    PaddingValues()
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

enum class TabDestinations(
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
fun TabDestinations.icon(isSelected: Boolean): ImageVector = ImageVector.vectorResource(
    when (this) {
        TabDestinations.TODAY ->
            if (isSelected)
                R.drawable.ic_tab_today_selected
            else
                R.drawable.ic_tab_today

        TabDestinations.JOURNAL ->
            if (isSelected)
                R.drawable.ic_tab_journal_selected
            else
                R.drawable.ic_tab_journal

        TabDestinations.PRINCIPAL ->
            if (isSelected)
                R.drawable.ic_tab_principles_selected
            else
                R.drawable.ic_tab_principles

        TabDestinations.SETTINGS ->
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
    val startDestination = TabDestinations.TODAY
    // Shared across tabs and the editor so a journal added from the editor shows up
    // in the Journal tab immediately (there is no server/DB yet to re-fetch from).
    val journalViewModel: JournalViewModel = hiltViewModel()
    // Shared by the settings list and the AI connection screen.
    val settingsViewModel: SettingsViewModel = hiltViewModel()
    val currentRoute = navBackStackEntry?.destination?.route
    var isJournalSearchActive by remember { mutableStateOf(false) }
    var journalScrollToTopSignal by remember { mutableIntStateOf(0) }

    var topAppBarModel by remember { mutableStateOf(TopAppBarModel(
        "",
        null,
        { TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState()) },
        { },
        { }))
    }
    val scrollBehavior = topAppBarModel.scrollBehavior()

    fun dynamicTopAppBar(model: TopAppBarModel) {
        topAppBarModel = model
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        // The expanded search screen extends its background under the status bar.
        containerColor = if (isJournalSearchActive) MPAColor.CONTAINER.color() else MPAColor.CANVAS.color(),
        topBar = {
            // The journal detail draws its own app bar.
            if (currentRoute != JOURNAL_DETAIL_PATTERN) {
                MPATopAppBar(topAppBarModel, scrollBehavior)
            }
        },
        bottomBar = {
            if (
                !isJournalSearchActive &&
                currentRoute != SETTINGS_AI_CONNECTION_ROUTE &&
                currentRoute != JOURNAL_DETAIL_PATTERN
            ) {
                NavigationBar(
                    containerColor = MPAColor.CONTAINER.color(),
                    tonalElevation = 0.dp,
                    windowInsets = NavigationBarDefaults.windowInsets,
                ) {
                    TabDestinations.entries.forEach { destinations ->
                        val isSelected = currentRoute == destinations.route
                        NavigationBarItem(
                            selected = isSelected,
                            colors = NavigationBarItemDefaults.colors(
                                indicatorColor = MPAColor.BRAND_CONTAINER.color(),
                                selectedTextColor = MPAColor.TEXT_PRIMARY.color(),
                                unselectedTextColor = MPAColor.TEXT_PRIMARY.color(),
                            ),
                            onClick = {
                                if (isSelected && destinations == TabDestinations.JOURNAL) {
                                    journalScrollToTopSignal += 1
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
                currentRoute != TabDestinations.JOURNAL.route &&
                currentRoute != TabDestinations.SETTINGS.route &&
                currentRoute != SETTINGS_AI_CONNECTION_ROUTE
            ) {
                WriteJournalFloatingActionButton()
            }
        },
        content = { innerPadding ->
            NavHost(
                navController,
                modifier = Modifier.padding(innerPadding),
                startDestination = startDestination.route
            ) {
                TabDestinations.entries.forEach { destination ->
                    composable(destination.route) {
                        CompositionLocalProvider(LocalInnerPadding provides innerPadding) {
                            when (destination) {
                                TabDestinations.TODAY -> HomeScreen(
                                    onAddJournal = { navController.navigate(JOURNAL_EDITOR_ROUTE) },
                                    dynamicTopAppBar = { dynamicTopAppBar(it) },
                                )
                                TabDestinations.JOURNAL -> JournalScreen(
                                    viewModel = journalViewModel,
                                    onWrite = { date -> navController.navigate("$JOURNAL_EDITOR_ROUTE?$JOURNAL_EDITOR_DATE_ARG=$date") },
                                    onOpenEntry = { navController.navigate("$JOURNAL_DETAIL_ROUTE/${it.id}") },
                                    onSearchActiveChange = { isJournalSearchActive = it },
                                    scrollToTopSignal = journalScrollToTopSignal,
                                    dynamicTopAppBar = { dynamicTopAppBar(it) },
                                )
                                TabDestinations.PRINCIPAL -> PrincipleScreen(
                                    dynamicTopAppBar = { dynamicTopAppBar(it) },
                                )
                                TabDestinations.SETTINGS -> SettingsScreen(
                                    viewModel = settingsViewModel,
                                    onOpenAIConnection = { navController.navigate(SETTINGS_AI_CONNECTION_ROUTE) },
                                    dynamicTopAppBar = { dynamicTopAppBar(it) },
                                )
                            }
                        }
                    }
                }
                composable(JOURNAL_DETAIL_PATTERN) {
                    JournalDetailScreen(
                        onBack = { navController.popBackStack() },
                        // TODO: JournalEditorScreen cannot open an existing entry yet (Part C, 상세에서 편집).
                        onEdit = {},
                        onDelete = { journal ->
                            // Back to the list first, then the undo snackbar (Part A 3.8).
                            navController.popBackStack(TabDestinations.JOURNAL.route, inclusive = false)
                            journalViewModel.deleteJournal(journal)
                        },
                        onOpenEntry = { navController.navigate("$JOURNAL_DETAIL_ROUTE/${it.id}") },
                        onOpenPrinciple = {
                            navController.navigate(TabDestinations.PRINCIPAL.route) {
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
                    route = "$JOURNAL_EDITOR_ROUTE?$JOURNAL_EDITOR_DATE_ARG={$JOURNAL_EDITOR_DATE_ARG}",
                    arguments = listOf(
                        navArgument(JOURNAL_EDITOR_DATE_ARG) {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        },
                    ),
                ) { entry ->
                    JournalEditorScreen(
                        viewModel = journalViewModel,
                        initialDate = entry.arguments?.getString(JOURNAL_EDITOR_DATE_ARG)?.let(LocalDate::parse),
                        onClose = { navController.popBackStack() },
                    )
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

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    MPA_AndroidTheme {
        App()
    }
}