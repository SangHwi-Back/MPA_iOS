package com.example.mpa_android.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

@Composable
fun MPA_AndroidTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }

        darkTheme -> darkColorScheme(
            primary = MPAColor.BRAND_PRIMARY.color(),
            onPrimary = MPAColor.BRAND_ON_PRIMARY.color(),
            primaryContainer = MPAColor.BRAND_CONTAINER.color(),
            onPrimaryContainer = MPAColor.BRAND_ON_CONTAINER.color(),

            secondary = MPAColor.AI_ACCENT.color(),
            onSecondary = MPAColor.TEXT_PRIMARY.color(),
            secondaryContainer = MPAColor.AI_TINT.color(),
            onSecondaryContainer = MPAColor.TEXT_PRIMARY.color(),

            tertiary = MPAColor.WARNING.color(),
            onTertiary = MPAColor.BRAND_ON_PRIMARY.color(),
            tertiaryContainer = MPAColor.HIGHLIGHT_SEARCH.color(),
            onTertiaryContainer = MPAColor.WARNING_TEXT.color(),

            error = MPAColor.DANGER.color(),
            onError = MPAColor.BRAND_ON_PRIMARY.color(),
            errorContainer = MPAColor.DANGER.color().copy(alpha = 0.16f),
            onErrorContainer = MPAColor.DANGER.color(),

            background = MPAColor.CANVAS.color(),
            onBackground = MPAColor.TEXT_PRIMARY.color(),
            surface = MPAColor.SURFACE.color(),
            onSurface = MPAColor.TEXT_PRIMARY.color(),
            surfaceVariant = MPAColor.SUNKEN.color(),
            onSurfaceVariant = MPAColor.TEXT_SECONDARY.color(),

            outline = MPAColor.HAIRLINE.color(),
            outlineVariant = MPAColor.HAIRLINE.color(),
            scrim = MPAColor.SCRIM.color(),

            inverseSurface = MPAColor.TEXT_PRIMARY.color(),
            inverseOnSurface = MPAColor.CANVAS.color(),
            inversePrimary = MPAColor.BRAND_CONTAINER.color(),
        )
        else -> lightColorScheme(
            primary = MPAColor.BRAND_PRIMARY.color(),
            onPrimary = MPAColor.BRAND_ON_PRIMARY.color(),
            primaryContainer = MPAColor.BRAND_CONTAINER.color(),
            onPrimaryContainer = MPAColor.BRAND_ON_CONTAINER.color(),

            secondary = MPAColor.AI_ACCENT.color(),
            onSecondary = MPAColor.BRAND_ON_PRIMARY.color(),
            secondaryContainer = MPAColor.AI_TINT.color(),
            onSecondaryContainer = MPAColor.TEXT_PRIMARY.color(),

            tertiary = MPAColor.WARNING.color(),
            onTertiary = MPAColor.BRAND_ON_PRIMARY.color(),
            tertiaryContainer = MPAColor.HIGHLIGHT_SEARCH.color(),
            onTertiaryContainer = MPAColor.WARNING_TEXT.color(),

            error = MPAColor.DANGER.color(),
            onError = MPAColor.BRAND_ON_PRIMARY.color(),
            errorContainer = MPAColor.DANGER.color().copy(alpha = 0.16f),
            onErrorContainer = MPAColor.DANGER.color(),

            background = MPAColor.CANVAS.color(),
            onBackground = MPAColor.TEXT_PRIMARY.color(),
            surface = MPAColor.SURFACE.color(),
            onSurface = MPAColor.TEXT_PRIMARY.color(),
            surfaceVariant = MPAColor.SUNKEN.color(),
            onSurfaceVariant = MPAColor.TEXT_SECONDARY.color(),

            outline = MPAColor.HAIRLINE.color(),
            outlineVariant = MPAColor.HAIRLINE.color(),
            scrim = MPAColor.SCRIM.color(),

            inverseSurface = MPAColor.TEXT_PRIMARY.color(),
            inverseOnSurface = MPAColor.CANVAS.color(),
            inversePrimary = MPAColor.BRAND_CONTAINER.color(),
        )
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
