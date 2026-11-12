// [NO AC] Spec: specs/home/SCREEN_SPEC.md
package com.example.mpa_android.ui.view

import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.mpa_android.R
import com.example.mpa_android.ui.theme.MPAColor

/** [WriteJournalFloatingActionButton]'s M3 extended height plus its scaffold margin: the space a scrolling screen behind it must reserve at the bottom. */
val WRITE_FAB_RESERVED_HEIGHT = 56.dp + 16.dp

/**
 * Extended "쓰기" FAB (Home 3.1).
 * - [label]: "쓰기", "이어 쓰기" (today's entry exists) or "첫 일기 쓰기" (first run).
 * - [isEmphasized]: Primary for the first run, Primary Container otherwise.
 * - [expanded]: collapses to the icon while scrolling down.
 */
@Composable
fun WriteJournalFloatingActionButton(
    modifier: Modifier = Modifier,
    label: String = "쓰기",
    isEmphasized: Boolean = false,
    expanded: Boolean = true,
    onClick: () -> Unit = {},
) {
    val content = if (isEmphasized) MPAColor.BRAND_ON_PRIMARY.color() else MPAColor.BRAND_ON_CONTAINER.color()
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
                contentDescription = if (expanded) null else label,
                modifier = Modifier.size(24.dp),
            )
        },
        expanded = expanded,
        onClick = onClick,
        modifier = modifier,
        containerColor = if (isEmphasized) MPAColor.BRAND_PRIMARY.color() else MPAColor.BRAND_CONTAINER.color(),
        contentColor = content,
    )
}
