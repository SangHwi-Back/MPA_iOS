// [NO AC] Spec: specs/home/SCREEN_SPEC.md
package com.example.mpa_android.ui.view

import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.mpa_android.LocalAppGlobalModel
import com.example.mpa_android.R
import com.example.mpa_android.ui.theme.MPAColor
import com.example.mpa_android.ui.view.home.homeFabLabel
import com.example.mpa_android.viewmodel.JournalViewModel

/** [WriteJournalFloatingActionButton]'s M3 extended height plus its scaffold margin: the space a scrolling screen behind it must reserve at the bottom. */
val WRITE_FAB_RESERVED_HEIGHT = 56.dp + 16.dp

/**
 * Extended "쓰기" FAB (Home 3.1).
 * - [isHome]: Is current navigation is HomeScreen.
 */
@Composable
fun WriteJournalFloatingActionButton(
    modifier: Modifier = Modifier,
    isHome: Boolean,
    onClick: () -> Unit = {},
) {
    val journalViewModel: JournalViewModel = hiltViewModel()
    val journals by journalViewModel.visibleJournals.collectAsState()
    val isEmphasized = journals.isEmpty()
    val content = if (isEmphasized) MPAColor.BRAND_ON_PRIMARY.color() else MPAColor.BRAND_ON_CONTAINER.color()
    val isExpanded = !isHome || LocalAppGlobalModel.current.isHomeFabExpanded

    val label = if (isHome) homeFabLabel(journals) else "쓰기"
    ExtendedFloatingActionButton(
        text = {
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
            )
        },
        icon = {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_edit),
                contentDescription = if (isExpanded) null else label,
                modifier = Modifier.size(24.dp),
            )
        },
        expanded = isExpanded,
        onClick = onClick,
        modifier = modifier,
        containerColor = if (isEmphasized) MPAColor.BRAND_PRIMARY.color() else MPAColor.BRAND_CONTAINER.color(),
        contentColor = content,
    )
}
