package com.example.mpa_android.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.ui.graphics.Color

enum class MPAColor {
    CANVAS, SURFACE, SUNKEN, CONTAINER,
    HAIRLINE, TEXT_PRIMARY, TEXT_SECONDARY, TEXT_TERTIARY,
    BRAND_PRIMARY, BRAND_ON_PRIMARY, BRAND_CONTAINER, BRAND_ON_CONTAINER,
    AI_TINT, AI_ACCENT, WARNING, WARNING_TEXT, DANGER,
    HIGHLIGHT_SEARCH, SCRIM, PRINCIPLE_1, PRINCIPLE_2,
    PRINCIPLE_3, PRINCIPLE_4, PRINCIPLE_5, ON_PRINCIPLE;

    @Composable
    @Stable
    fun color(): Color = when (this) {
        CANVAS -> if (isSystemInDarkTheme()) AppColor.Dark.CANVAS else AppColor.Light.CANVAS
        SURFACE -> if (isSystemInDarkTheme()) AppColor.Dark.SURFACE else AppColor.Light.SURFACE
        SUNKEN -> if (isSystemInDarkTheme()) AppColor.Dark.SUNKEN else AppColor.Light.SUNKEN
        CONTAINER -> if (isSystemInDarkTheme()) AppColor.Dark.CONTAINER else AppColor.Light.CONTAINER
        HAIRLINE -> if (isSystemInDarkTheme()) AppColor.Dark.HAIRLINE else AppColor.Light.HAIRLINE
        TEXT_PRIMARY -> if (isSystemInDarkTheme()) AppColor.Dark.TEXT_PRIMARY else AppColor.Light.TEXT_PRIMARY
        TEXT_SECONDARY -> if (isSystemInDarkTheme()) AppColor.Dark.TEXT_SECONDARY else AppColor.Light.TEXT_SECONDARY
        TEXT_TERTIARY -> if (isSystemInDarkTheme()) AppColor.Dark.TEXT_TERTIARY else AppColor.Light.TEXT_TERTIARY
        BRAND_PRIMARY -> if (isSystemInDarkTheme()) AppColor.Dark.BRAND_PRIMARY else AppColor.Light.BRAND_PRIMARY
        BRAND_ON_PRIMARY -> if (isSystemInDarkTheme()) AppColor.Dark.BRAND_ON_PRIMARY else AppColor.Light.BRAND_ON_PRIMARY
        BRAND_CONTAINER -> if (isSystemInDarkTheme()) AppColor.Dark.BRAND_CONTAINER else AppColor.Light.BRAND_CONTAINER
        BRAND_ON_CONTAINER -> if (isSystemInDarkTheme()) AppColor.Dark.BRAND_ON_CONTAINER else AppColor.Light.BRAND_ON_CONTAINER
        AI_TINT -> if (isSystemInDarkTheme()) AppColor.Dark.AI_TINT else AppColor.Light.AI_TINT
        AI_ACCENT -> if (isSystemInDarkTheme()) AppColor.Dark.AI_ACCENT else AppColor.Light.AI_ACCENT
        WARNING -> if (isSystemInDarkTheme()) AppColor.Dark.WARNING else AppColor.Light.WARNING
        WARNING_TEXT -> if (isSystemInDarkTheme()) AppColor.Dark.WARNING_TEXT else AppColor.Light.WARNING_TEXT
        DANGER -> if (isSystemInDarkTheme()) AppColor.Dark.DANGER else AppColor.Light.DANGER
        HIGHLIGHT_SEARCH -> if (isSystemInDarkTheme()) AppColor.Dark.HIGHLIGHT_SEARCH else AppColor.Light.HIGHLIGHT_SEARCH
        SCRIM -> if (isSystemInDarkTheme()) AppColor.Dark.SCRIM else AppColor.Light.SCRIM
        PRINCIPLE_1 -> if (isSystemInDarkTheme()) AppColor.Dark.PRINCIPLE_1 else AppColor.Light.PRINCIPLE_1
        PRINCIPLE_2 -> if (isSystemInDarkTheme()) AppColor.Dark.PRINCIPLE_2 else AppColor.Light.PRINCIPLE_2
        PRINCIPLE_3 -> if (isSystemInDarkTheme()) AppColor.Dark.PRINCIPLE_3 else AppColor.Light.PRINCIPLE_3
        PRINCIPLE_4 -> if (isSystemInDarkTheme()) AppColor.Dark.PRINCIPLE_4 else AppColor.Light.PRINCIPLE_4
        PRINCIPLE_5 -> if (isSystemInDarkTheme()) AppColor.Dark.PRINCIPLE_5 else AppColor.Light.PRINCIPLE_5
        ON_PRINCIPLE -> if (isSystemInDarkTheme()) AppColor.Dark.ON_PRINCIPLE else AppColor.Light.ON_PRINCIPLE
    }
}

object AppColor {
    object Light {
        // Background
        val CANVAS = Color(0xFFFAF8F5) // bg/canvas — screen background
        val SURFACE = Color(0xFFFFFFFF) // bg/surface — cards (user writing)
        val SUNKEN = Color(0xFFF3F0EB) // bg/sunken — settings bg, list pane, input fields
        val CONTAINER = Color(0xFFF2EEE8) // bg/container — navigation bar, menus, sheets
        val HAIRLINE = Color(0xFFECE7E0) // border/hairline — dividers, card outline

        // Text
        val TEXT_PRIMARY = Color(0xFF1C1B1A) // text/primary — body, user text
        val TEXT_SECONDARY = Color(0xFF6B6660) // text/secondary — meta, dates, labels (≥ 4.5:1)
        val TEXT_TERTIARY = Color(0xFF8A837B) // text/tertiary — 16sp+ / decorative only (3:1)

        // Brand
        val BRAND_PRIMARY = Color(0xFF2E3A6E) // brand/primary — primary buttons, links, selection
        val BRAND_ON_PRIMARY = Color(0xFFFFFFFF) // brand/on-primary
        val BRAND_CONTAINER =
            Color(0xFFDCE0F4) // brand/container — FAB, active indicator, selected row
        val BRAND_ON_CONTAINER = Color(0xFF1E2754) // brand/on-container

        // AI
        val AI_TINT = Color(0xFFF1EFF9) // ai/tint — AI card background
        val AI_ACCENT = Color(0xFF5B4DBA) // ai/accent — ✦ icon, AI section labels

        // Status / feedback
        val WARNING = Color(0xFFD97A1E) // status/warning — AI warning button background
        val WARNING_TEXT = Color(0xFFB35F0F) // status/warning — warning text
        val DANGER = Color(0xFFC4342A) // feedback/danger — delete, disconnect
        val HIGHLIGHT_SEARCH = Color(0xFFF6E2B4) // highlight/search — search match
        val SCRIM = Color(0x52141312) // scrim — #141312 @ 32%

        // Principle bubbles — recency scale (1 = most recent → 5 = oldest)
        val PRINCIPLE_1 = Color(0xFFEE937B)
        val PRINCIPLE_2 = Color(0xFFF2B48E)
        val PRINCIPLE_3 = Color(0xFFE9CF97)
        val PRINCIPLE_4 = Color(0xFFC9D9A6)
        val PRINCIPLE_5 = Color(0xFFA9CBB0)
        val ON_PRINCIPLE = Color(0xFF2A211C) // label text on bubbles

        val PRINCIPLE_SCALE: List<Color> =
            listOf(PRINCIPLE_1, PRINCIPLE_2, PRINCIPLE_3, PRINCIPLE_4, PRINCIPLE_5)
    }

    object Dark {
        // Background
        val CANVAS = Color(0xFF141312)
        val SURFACE = Color(0xFF1E1C1B)
        val SUNKEN = Color(0xFF1A1817)
        val CONTAINER = Color(0xFF262321)
        val HAIRLINE = Color(0xFF2E2B28)

        // Text
        val TEXT_PRIMARY = Color(0xFFF2EFEA)
        val TEXT_SECONDARY = Color(0xFFA39D96)
        val TEXT_TERTIARY = Color(0xFF7E7871)

        // Brand
        val BRAND_PRIMARY = Color(0xFFAEB8F0)
        val BRAND_ON_PRIMARY = Color(0xFF1A2150)
        val BRAND_CONTAINER = Color(0xFF2F3864)
        val BRAND_ON_CONTAINER = Color(0xFFDCE0F4)

        // AI
        val AI_TINT = Color(0xFF221F2E)
        val AI_ACCENT = Color(0xFFB3A8F0)

        // Status / feedback
        val WARNING = Color(0xFFE8973F)
        val WARNING_TEXT = Color(0xFFE8973F)
        val DANGER = Color(0xFFF0857A)
        val HIGHLIGHT_SEARCH = Color(0xFF5A4A22)
        val SCRIM = Color(0x80000000) // #000000 @ 50%

        // Principle bubbles — recency scale (1 = most recent → 5 = oldest)
        val PRINCIPLE_1 = Color(0xFFC77562)
        val PRINCIPLE_2 = Color(0xFFC99472)
        val PRINCIPLE_3 = Color(0xFFBBA676)
        val PRINCIPLE_4 = Color(0xFF9BAE80)
        val PRINCIPLE_5 = Color(0xFF82A38A)
        val ON_PRINCIPLE = Color(0xFF141312)

        val PRINCIPLE_SCALE: List<Color> =
            listOf(PRINCIPLE_1, PRINCIPLE_2, PRINCIPLE_3, PRINCIPLE_4, PRINCIPLE_5)
    }
}