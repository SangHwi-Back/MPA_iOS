package com.example.mpa_android.ui.view

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.mpa_android.R
import com.example.mpa_android.ui.theme.MPAColor

@Composable
fun WriteJournalFloatingActionButton() {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(MPAColor.BRAND_CONTAINER.color())
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(
            imageVector = ImageVector.vectorResource(R.drawable.ic_edit),
            contentDescription = null,
            tint = MPAColor.BRAND_ON_CONTAINER.color(),
            modifier = Modifier.size(18.dp),
        )
        Text(
            text = "쓰기",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MPAColor.BRAND_ON_CONTAINER.color(),
        )
    }
}
