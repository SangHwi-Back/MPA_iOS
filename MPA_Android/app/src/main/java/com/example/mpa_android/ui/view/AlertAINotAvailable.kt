package com.example.mpa_android.ui.view

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.mpa_android.R
import com.example.mpa_android.ui.theme.MPAColor

@Composable
fun AlertAINotAvailable(
    onAIConnectionRequest: () -> Unit,
    onDismissRequest: () -> Unit
) {
    Dialog(onDismissRequest = onDismissRequest) {
        Column(
            modifier = Modifier
                .clip(RoundedCornerShape(24.dp))
                .background(MPAColor.CANVAS.color())
                .padding(24.dp)
        ) {
            Row(modifier = Modifier.padding(bottom = 16.dp)) {
                Spacer(Modifier.weight(1f))
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_alert_dialog),
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                    tint = MPAColor.WARNING.color()
                )
                Spacer(Modifier.weight(1f))
            }

            Text(
                text = "AI 기능을 사용할 수 없어요",
                fontWeight = FontWeight.Bold,
                fontSize = 22.sp,
                modifier = Modifier
                    .padding(bottom = 16.dp)
            )

            Text(
                text = "이 기기는 Gemini Nano를 지원하지 않아요. 일기 쓰기는 그대로 사용할 수 있어요.",
                modifier = Modifier.padding(bottom = 24.dp)
            )

            Row {
                Spacer(Modifier.weight(1f))
                ButtonLabel(
                    "API 키 연결",
                    onClick = onAIConnectionRequest
                )
                ButtonLabel(
                    "확인",
                    onClick = onDismissRequest
                )
            }
        }
    }
}

@Composable
private fun ButtonLabel(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Text(
        text = text,
        fontWeight = FontWeight.Black,
        color = MPAColor.BRAND_PRIMARY.color(),
        modifier = modifier.padding(10.dp).clickable {
            onClick()
        }
    )
}

@Preview
@Composable
fun PreviewAlertAINotAvailable() {
    Box(modifier = Modifier.fillMaxSize().background(MPAColor.CANVAS.color())) {
        AlertAINotAvailable(
            onAIConnectionRequest = {},
            onDismissRequest = {}
        )
    }
}