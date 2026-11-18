// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
package com.example.mpa_android.ui.view.settings

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.example.mpa_android.R
import com.example.mpa_android.ui.TestTags
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalExportFormat
import com.example.mpa_android.model.JournalExporter
import com.example.mpa_android.ui.theme.MPAColor
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/** "기록을 내보낼까요?" dialog. 내보내기 writes the file in the chosen format and opens the share sheet. */
@Composable
fun SettingsAlertExportJournalsScreen(
    journals: List<Journal>,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    ExportJournalsDialog(
        count = journals.size,
        onExport = { format ->
            onDismiss()
            shareExport(context, journals, format)
        },
        onDismiss = onDismiss,
    )
}

@Composable
private fun ExportJournalsDialog(
    count: Int,
    onExport: (JournalExportFormat) -> Unit,
    onDismiss: () -> Unit,
) {
    var format by remember { mutableStateOf(JournalExportFormat.MARKDOWN) }

    AlertDialog(
        onDismissRequest = onDismiss,
        // Dialogs are separate windows, so the app root's testTagsAsResourceId does not reach them.
        modifier = Modifier
            .testTag(TestTags.AlertExportJournals.SCREEN)
            .semantics { testTagsAsResourceId = true },
        containerColor = MPAColor.CONTAINER.color(),
        icon = {
            Icon(
                imageVector = ImageVector.vectorResource(R.drawable.ic_settings_export),
                contentDescription = null,
                tint = MPAColor.BRAND_PRIMARY.color(),
            )
        },
        title = { Text("기록을 내보낼까요?", color = MPAColor.TEXT_PRIMARY.color()) },
        text = {
            Column {
                Text(
                    text = exportMessage(count),
                    fontSize = 15.sp,
                    lineHeight = 23.sp,
                    color = MPAColor.TEXT_SECONDARY.color(),
                    modifier = Modifier.testTag(TestTags.AlertExportJournals.MESSAGE),
                )
                Spacer(Modifier.height(16.dp))
                Column(Modifier.selectableGroup()) {
                    ExportOption(
                        "텍스트 (.md)",
                        "읽기 쉬운 문서",
                        format == JournalExportFormat.MARKDOWN,
                        Modifier.testTag(TestTags.AlertExportJournals.OPTION_MARKDOWN),
                    ) {
                        format = JournalExportFormat.MARKDOWN
                    }
                    ExportOption(
                        "JSON",
                        "다른 앱으로 옮길 때",
                        format == JournalExportFormat.JSON,
                        Modifier.testTag(TestTags.AlertExportJournals.OPTION_JSON),
                    ) {
                        format = JournalExportFormat.JSON
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { onExport(format) }, modifier = Modifier.testTag(TestTags.AlertExportJournals.CONFIRM)) {
                Text("내보내기", color = MPAColor.BRAND_PRIMARY.color())
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, modifier = Modifier.testTag(TestTags.AlertExportJournals.CANCEL)) {
                Text("취소", color = MPAColor.BRAND_PRIMARY.color())
            }
        },
    )
}

@Composable
private fun ExportOption(
    title: String,
    subtitle: String,
    selected: Boolean,
    modifier: Modifier = Modifier,
    onSelect: () -> Unit,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .selectable(selected = selected, onClick = onSelect, role = Role.RadioButton),
    ) {
        RadioButton(
            selected = selected,
            onClick = null,
            colors = RadioButtonDefaults.colors(
                selectedColor = MPAColor.BRAND_PRIMARY.color(),
                unselectedColor = MPAColor.TEXT_SECONDARY.color(),
            ),
        )
        Spacer(Modifier.width(16.dp))
        Column {
            Text(title, fontSize = 17.sp, color = MPAColor.TEXT_PRIMARY.color())
            Text(subtitle, fontSize = 14.sp, color = MPAColor.TEXT_SECONDARY.color())
        }
    }
}

internal fun exportMessage(count: Int) =
    "일기 ${count}편의 날짜·제목·본문·키워드를 파일 하나로 만들어 공유해요. 사진은 포함되지 않아요. 내보낸 파일은 앱 잠금으로 보호되지 않으니 보관할 곳을 신중히 골라 주세요."

/** Writes the export into the cache and opens the system share sheet for it. */
private fun shareExport(context: Context, journals: List<Journal>, format: JournalExportFormat) {
    val directory = File(context.cacheDir, "exports").apply { mkdirs() }
    val date = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
    val file = File(directory, "MPA-journals-$date.${format.fileExtension}")
    file.writeText(JournalExporter.content(journals, format))
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    val send = Intent(Intent.ACTION_SEND)
        .setType(format.mimeType)
        .putExtra(Intent.EXTRA_STREAM, uri)
        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    context.startActivity(Intent.createChooser(send, null))
}

@Preview(name = "alertExportJournals", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun AlertExportJournalsPreview() {
    ExportJournalsDialog(count = 12, onExport = {}, onDismiss = {})
}
