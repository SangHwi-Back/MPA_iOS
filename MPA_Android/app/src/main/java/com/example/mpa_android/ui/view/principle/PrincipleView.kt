package com.example.mpa_android.ui.view.principle

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CornerSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.mpa_android.ui.theme.MPAColor

@Composable
fun PrincipleView() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MPAColor.CANVAS.color())
    ) {
        Header(Modifier.padding(16.dp))
        Spacer(Modifier.height(8.dp))
        Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
            PrincipalList()
            Spacer(Modifier.height(32.dp))
            PrincipalAlreadyLeft()
        }
        Spacer(Modifier.height(24.dp))

    }
}

@Composable
private fun Header(modifier: Modifier) {
    Column(modifier) {
        Text(
            text = "원칙",
            fontWeight = FontWeight.Bold,
            fontSize = 30.sp,
            color = MPAColor.TEXT_PRIMARY.color(),
            modifier = Modifier.padding(bottom = 2.dp)
        )
        Text(
            text = "일기 12개에서 찾았어요 · 10월 30일 갱신",
            fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
        )
    }
}

@Composable
private fun PrincipalList() {
    Column {
        Text(
            text = "지금의 원칙",
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
            modifier = Modifier.padding(
                start = 16.dp,
                bottom = 24.dp
            )
        )

        PrincipalModel.samples.forEachIndexed { index, model ->
                PrincipalListItem(index, model)
                Box(modifier = Modifier
                    .background(color = MPAColor.TEXT_SECONDARY.color().copy(alpha = 0.1f))
                    .height(1.dp)
                    .fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
        }
    }
}
private data class PrincipalModel(
    val color: Color,
    val title: String,
    val description: String,
    val chip: String? = null,
    val isAnchored: Boolean = false,
    val gauge: Float,
) {
    companion object {
        val samples: List<PrincipalModel>
            @Composable
            get() = listOf(
                PrincipalModel(
                    MPAColor.PRINCIPLE_1.color(),
                    title = "경청",
                    description = "7편 · 마지막 10월 27일",
                    gauge = 1f
                ),
                PrincipalModel(
                    MPAColor.PRINCIPLE_2.color(),
                    title = "꾸준함",
                    isAnchored = true,
                    description = "5편 · 마지막 10월 29일",
                    gauge = 0.7f
                ),
                PrincipalModel(
                    MPAColor.PRINCIPLE_3.color(),
                    title = "솔직함",
                    description = "4편 · 마지막 10월 27일\n",
                    gauge = 0.5f
                ),
                PrincipalModel(
                    MPAColor.PRINCIPLE_4.color(),
                    title = "휴식",
                    chip = "새로",
                    description = "3편 · 마지막 10월 30일",
                    gauge = 0.35f
                ),
                PrincipalModel(
                    MPAColor.PRINCIPLE_5.color(),
                    title = "감사",
                    description = "2편 · 마지막 10월 26일\n",
                    gauge = 0.2f
                ),
            )
    }
}

@Composable
private fun PrincipalListItem(index: Int, model: PrincipalModel) {
    Row(modifier = Modifier
        .padding(
            start = 16.dp,
            end = 16.dp,
            bottom = 8.dp
        ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "${index+1}",
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.TEXT_SECONDARY.color(),
            fontSize = 17.sp,
            modifier = Modifier.padding(end = 12.dp)
        )
        Box(modifier = Modifier
            .clip(CircleShape)
            .background(color = model.color)
            .size(44.dp)
        )
        Column(modifier = Modifier.weight(1f).padding(start = 12.dp)) {
            Text(
                text = model.title,
                fontWeight = FontWeight.Bold,
                fontSize = 17.sp,
                color = MPAColor.TEXT_PRIMARY.color()
            )
            Text(
                text = model.description,
                fontWeight = FontWeight.Medium,
                fontSize = 12.5.sp,
                color = MPAColor.TEXT_SECONDARY.color()
            )
        }
        Box(modifier = Modifier.fillMaxWidth(0.3f)) {
            Box(modifier = Modifier
                .clip(RoundedCornerShape(corner = CornerSize(3.dp)))
                .background(color = MPAColor.HAIRLINE.color())
                .fillMaxWidth()
                .height(8.dp)
            )
            Box(modifier = Modifier
                .clip(RoundedCornerShape(corner = CornerSize(3.dp)))
                .background(color = MPAColor.BRAND_ON_CONTAINER.color())
                .fillMaxWidth(model.gauge)
                .height(8.dp)
            )
        }
    }
}

private data class PastPrincipalModel(
    val month: String,
    val duration: String,
    val rank: Int,
    val title: String,
)

private val pastPrincipalSamples = listOf(
    PastPrincipalModel(month = "9월", duration = "3주", rank = 1, title = "인내"),
    PastPrincipalModel(month = "8월", duration = "2주", rank = 2, title = "운동"),
)

@Composable
private fun PrincipalAlreadyLeft() {
    Column {
        Text(
            text = "지나간 원칙",
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = MPAColor.TEXT_SECONDARY.color(),
            modifier = Modifier.padding(start = 16.dp, bottom = 24.dp)
        )
        pastPrincipalSamples.forEachIndexed { index, model ->
            PastPrincipalTimelineItem(
                model = model,
                isLast = index == pastPrincipalSamples.lastIndex,
            )
        }
    }
}

@Composable
private fun PastPrincipalTimelineItem(model: PastPrincipalModel, isLast: Boolean) {
    Row(
        modifier = Modifier
            .padding(start = 16.dp, end = 16.dp)
            .height(IntrinsicSize.Min)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .width(20.dp)
                .fillMaxHeight()
        ) {
            Box(
                modifier = Modifier
                    .padding(top = 4.dp)
                    .size(10.dp)
                    .clip(CircleShape)
                    .border(
                        width = 1.5.dp,
                        color = MPAColor.TEXT_SECONDARY.color().copy(alpha = 0.4f),
                        shape = CircleShape,
                    )
            )
            if (!isLast) {
                Box(
                    modifier = Modifier
                        .padding(top = 4.dp)
                        .width(1.dp)
                        .weight(1f)
                        .background(MPAColor.HAIRLINE.color())
                )
            }
        }
        Spacer(Modifier.width(12.dp))
        Column(
            modifier = Modifier.padding(bottom = if (isLast) 0.dp else 20.dp)
        ) {
            Text(
                text = "${model.month} · ${model.duration} 동안 ${model.rank}위",
                fontWeight = FontWeight.Medium,
                fontSize = 13.sp,
                color = MPAColor.TEXT_SECONDARY.color(),
                modifier = Modifier.padding(bottom = 2.dp)
            )
            Text(
                text = model.title,
                fontWeight = FontWeight.Bold,
                fontSize = 17.sp,
                color = MPAColor.TEXT_PRIMARY.color(),
            )
        }
    }
}

@Preview(uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DarkPreviewPrincipleView() {
    PrincipleView()
}

@Preview(uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable
private fun LightPreviewPrincipleView() {
    PrincipleView()
}