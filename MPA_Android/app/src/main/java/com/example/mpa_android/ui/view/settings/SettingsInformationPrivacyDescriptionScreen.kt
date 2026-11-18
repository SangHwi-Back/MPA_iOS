// [NO AC] Spec: specs/settings/SCREEN_SPEC.md
package com.example.mpa_android.ui.view.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.mpa_android.R
import com.example.mpa_android.ui.TestTags
import com.example.mpa_android.model.AIConnectionState
import com.example.mpa_android.model.AIProvider
import com.example.mpa_android.ui.theme.MPAColor

/**
 * "데이터는 어디에 저장되나요?" — where journals live and where each AI reads them.
 * The app bar stays on top and takes the container color once the content scrolls under it.
 */
@Composable
fun SettingsInformationPrivacyDescriptionScreen(
    aiConnection: AIConnectionState,
    onBack: () -> Unit,
    startsAtBottom: Boolean = false,
) {
    val scrollState = rememberScrollState()
    LaunchedEffect(startsAtBottom, scrollState.maxValue) {
        if (startsAtBottom) scrollState.scrollTo(scrollState.maxValue)
    }

    Column(modifier = Modifier.testTag(TestTags.InformationPrivacyDescription.SCREEN).fillMaxSize().background(MPAColor.CANVAS.color())) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(if (scrollState.value > 0) MPAColor.CONTAINER.color() else Color.Transparent)
                .statusBarsPadding()
                .height(64.dp)
                .padding(start = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack, modifier = Modifier.testTag(TestTags.InformationPrivacyDescription.BACK)) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_arrow_back),
                    contentDescription = "뒤로",
                    tint = MPAColor.TEXT_PRIMARY.color(),
                )
            }
            Spacer(Modifier.width(4.dp))
            Text(text = "데이터 저장 위치", fontSize = 24.sp, color = MPAColor.TEXT_PRIMARY.color())
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(horizontal = SettingsGutter)
                .padding(top = 12.dp, bottom = 40.dp),
        ) {
            Text(
                text = "데이터는 어디에 저장되나요?",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = MPAColor.TEXT_PRIMARY.color(),
                modifier = Modifier.testTag(TestTags.InformationPrivacyDescription.TITLE).semantics { heading() },
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "MPA에는 개발자가 운영하는 서버가 없어요. 일기는 이 휴대전화 안에만 저장되고, AI가 일기를 어디에서 읽는지는 연결한 AI에 따라 달라요.",
                fontSize = 16.sp,
                lineHeight = 25.sp,
                color = MPAColor.TEXT_PRIMARY.color(),
            )

            PrivacyHeader("일기와 사진")
            PrivacyBulletCard(
                listOf(
                    "일기·사진·키워드는 이 휴대전화의 앱 저장 공간에만 저장돼요. 개발자를 포함해 누구에게도 자동으로 보내지 않아요.",
                    "Google 기기 백업을 켜 두었다면 백업에 함께 들어갈 수 있어요.",
                    "사진과 사진 캡션은 어떤 AI에도 보내지 않아요.",
                ),
                modifier = Modifier.testTag(TestTags.InformationPrivacyDescription.STORAGE),
            )

            PrivacyHeader("AI가 일기를 읽는 곳")
            PrivacyReaderCard(
                name = "Gemini Nano",
                tagKey = "onDevice",
                chips = listOfNotNull(PrivacyChip.ON_DEVICE, PrivacyChip.IN_USE.takeIf { isInUse(aiConnection, null) }),
                text = "휴대전화에 내장된 AI(Gemini Nano)가 이 휴대전화 안에서 일기를 읽고 조언·요약·원칙을 만들어요. 일기가 기기 밖으로 나가지 않아요.",
            )
            AIProvider.entries.forEach { provider ->
                Spacer(Modifier.height(16.dp))
                PrivacyReaderCard(
                    name = "${provider.displayName} (내 API 키)",
                    tagKey = if (provider == AIProvider.GEMINI) "gemini" else "openAI",
                    chips = listOfNotNull(PrivacyChip.EXTERNAL, PrivacyChip.IN_USE.takeIf { isInUse(aiConnection, provider) }),
                    text = externalText(provider),
                )
            }
            Text(
                text = "API 키는 이 휴대전화의 Android 키 저장소에만 저장되고, 화면에는 일부만 보여요.",
                fontSize = 13.sp,
                lineHeight = 19.sp,
                color = MPAColor.TEXT_SECONDARY.color(),
                modifier = Modifier.padding(start = 8.dp, end = 8.dp, top = 12.dp),
            )

            PrivacyHeader("지우거나 앱을 삭제하면")
            PrivacyBulletCard(
                listOf(
                    "일기를 지우면 실행 취소 시간이 지난 뒤 이 기기에서 완전히 지워져요.",
                    "앱을 삭제하면 기기에 있던 일기도 함께 지워져요. 필요하면 먼저 ‘기록 내보내기’로 파일을 저장해 두세요.",
                    "이미 Gemini·OpenAI로 보낸 내용은 각 제공자의 정책에 따라 처리돼요.",
                ),
                modifier = Modifier.testTag(TestTags.InformationPrivacyDescription.DELETION),
            )
        }
    }
}

/** `null` provider means the on-device AI. */
private fun isInUse(state: AIConnectionState, provider: AIProvider?): Boolean = when (state) {
    is AIConnectionState.DeviceAI -> provider == null
    is AIConnectionState.Connected -> provider == state.connection.provider
    is AIConnectionState.KeyError -> provider == state.connection.provider
    is AIConnectionState.NotConnected -> false
}

private fun externalText(provider: AIProvider): String = when (provider) {
    AIProvider.GEMINI -> "가능하면 기기에서 줄인 요약·키워드만, 조언에 꼭 필요할 때는 본문 일부도 Google 서버로 보내요. 보낸 내용의 처리와 보관은 Google의 Gemini API 정책과 내 키 계정 설정을 따라요."
    AIProvider.OPENAI -> "가능하면 기기에서 줄인 요약·키워드만, 조언에 꼭 필요할 때는 본문 일부도 OpenAI 서버로 보내요. 보낸 내용의 처리와 보관은 OpenAI API 정책과 내 키 계정 설정을 따라요."
}

@Composable
private fun PrivacyHeader(text: String) {
    Text(
        text = text,
        fontSize = 14.sp,
        fontWeight = FontWeight.Bold,
        color = MPAColor.BRAND_PRIMARY.color(),
        modifier = Modifier
            .padding(top = 28.dp, bottom = 12.dp)
            .semantics { heading() },
    )
}

private val PrivacyCardShape = RoundedCornerShape(24.dp)

@Composable
private fun PrivacyBulletCard(items: List<String>, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(MPAColor.CONTAINER.color(), PrivacyCardShape)
            .padding(horizontal = 16.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        items.forEach { item ->
            Row {
                Box(
                    modifier = Modifier
                        .padding(top = 9.dp, end = 12.dp)
                        .size(5.dp)
                        .background(MPAColor.TEXT_TERTIARY.color().copy(alpha = 0.6f), CircleShape),
                )
                Text(text = item, fontSize = 15.sp, lineHeight = 23.sp, color = MPAColor.TEXT_PRIMARY.color())
            }
        }
    }
}

@Composable
private fun PrivacyReaderCard(name: String, tagKey: String, chips: List<PrivacyChip>, text: String) {
    Column(
        modifier = Modifier
            .testTag(TestTags.InformationPrivacyDescription.reader(tagKey))
            .fillMaxWidth()
            .background(MPAColor.CONTAINER.color(), PrivacyCardShape)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(text = name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = MPAColor.TEXT_PRIMARY.color())
            chips.forEach { chip ->
                PrivacyChipLabel(
                    chip,
                    modifier = if (chip == PrivacyChip.IN_USE) {
                        Modifier.testTag(TestTags.InformationPrivacyDescription.readerInUse(tagKey))
                    } else {
                        Modifier
                    },
                )
            }
        }
        Text(text = text, fontSize = 15.sp, lineHeight = 23.sp, color = MPAColor.TEXT_PRIMARY.color())
    }
}

/**
 * Green = stays on device, brand = in use, warning = leaves the device.
 * There is no green token yet, so the on-device chip uses its own pair.
 */
private enum class PrivacyChip(val title: String) {
    ON_DEVICE("기기 안"),
    IN_USE("지금 사용 중"),
    EXTERNAL("외부 전송"),
}

@Composable
private fun PrivacyChipLabel(chip: PrivacyChip, modifier: Modifier = Modifier) {
    val (background, foreground) = when (chip) {
        PrivacyChip.ON_DEVICE -> Color(0xFFDEF0DE) to Color(0xFF26592F)
        PrivacyChip.IN_USE -> MPAColor.BRAND_CONTAINER.color() to MPAColor.BRAND_ON_CONTAINER.color()
        PrivacyChip.EXTERNAL -> MPAColor.WARNING.color().copy(alpha = 0.15f) to MPAColor.WARNING_TEXT.color()
    }
    Text(
        text = chip.title,
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold,
        color = foreground,
        modifier = modifier
            .background(background, RoundedCornerShape(percent = 50))
            .padding(horizontal = 10.dp, vertical = 2.dp),
    )
}

@Preview(name = "informationPrivacyDescription", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun InformationPrivacyDescriptionPreview() {
    SettingsInformationPrivacyDescriptionScreen(aiConnection = AIConnectionState.DeviceAI(false), onBack = {})
}

@Preview(name = "informationPrivacyDescription-beneath", showBackground = true, widthDp = 412, heightDp = 915)
@Composable
private fun InformationPrivacyDescriptionBeneathPreview() {
    SettingsInformationPrivacyDescriptionScreen(
        aiConnection = AIConnectionState.DeviceAI(false),
        onBack = {},
        startsAtBottom = true,
    )
}
