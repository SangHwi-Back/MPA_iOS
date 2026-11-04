package com.example.mpa_android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarDefaults
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.mpa_android.ui.theme.MPA_AndroidTheme
import com.example.mpa_android.ui.view.JournalEditorScreen
import com.example.mpa_android.ui.view.JournalHomeView
import com.example.mpa_android.ui.view.PrincipalHomeView
import com.example.mpa_android.ui.view.SettingsHomeView
import com.example.mpa_android.ui.view.TodayHomeView
import com.example.mpa_android.ui.view.WriteJournalFloatingActionButton
import com.example.mpa_android.viewmodel.JournalViewModel
import dagger.hilt.android.AndroidEntryPoint

private const val JOURNAL_EDITOR_ROUTE = "journal-editor"

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

@Composable
fun App() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val startDestination = TabDestinations.TODAY
    // Shared across tabs and the editor so a journal added from the editor shows up
    // in the Journal tab immediately (there is no server/DB yet to re-fetch from).
    val journalViewModel: JournalViewModel = hiltViewModel()

    Scaffold(
        bottomBar = {
            NavigationBar(windowInsets = NavigationBarDefaults.windowInsets) {
                TabDestinations.entries.forEach { destinations ->
                    val isSelected = navBackStackEntry?.destination?.route == destinations.route
                    NavigationBarItem(
                        selected = isSelected,
                        onClick = {
                            navController.navigate(destinations.route) {
                                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        label = {
                            Text(
                                text = destinations.label,
                                fontWeight = if (isSelected) FontWeight.Black else FontWeight.Medium,
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
        },
        floatingActionButton = {
            WriteJournalFloatingActionButton()
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
                                TabDestinations.TODAY -> TodayHomeView(
                                    onAddJournal = { navController.navigate(JOURNAL_EDITOR_ROUTE) },
                                )
                                TabDestinations.JOURNAL -> JournalHomeView(viewModel = journalViewModel)
                                TabDestinations.PRINCIPAL -> PrincipalHomeView()
                                TabDestinations.SETTINGS -> SettingsHomeView()
                            }
                        }
                    }
                }
                composable(JOURNAL_EDITOR_ROUTE) {
                    JournalEditorScreen(
                        viewModel = journalViewModel,
                        onClose = { navController.popBackStack() },
                    )
                }
            }
        }
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    MPA_AndroidTheme {
        App()
    }
}