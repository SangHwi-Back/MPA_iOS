//
//  Color.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/2/26.
//

import SwiftUI

// MARK: Light
enum LightColorHex {
    // Background
    static let canvas            = "#FAF8F5"   // bg/canvas — screen background
    static let surface           = "#FFFFFF"   // bg/surface — cards (user writing)
    static let sunken            = "#F3F0EB"   // bg/sunken — settings bg, list pane, input fields
    static let container         = "#F2EEE8"   // bg/container — Android nav bar, menus, sheets
    static let hairline          = "#ECE7E0"   // border/hairline — dividers, card outline
    
    // Text
    static let textPrimary       = "#1C1B1A"   // text/primary — body, user text
    static let textSecondary     = "#6B6660"   // text/secondary — meta, dates, labels (≥ 4.5:1)
    static let textTertiary      = "#8A837B"   // text/tertiary — 16pt+ / decorative only (3:1)
    
    // Brand
    static let brandPrimary      = "#2E3A6E"   // brand/primary — primary buttons, links, selection
    static let brandOnPrimary    = "#FFFFFF"   // brand/on-primary
    static let brandContainer    = "#DCE0F4"   // brand/container — FAB, active indicator, selected row
    static let brandOnContainer  = "#1E2754"   // brand/on-container
    
    // AI
    static let aiTint            = "#F1EFF9"   // ai/tint — AI card background
    static let aiAccent          = "#5B4DBA"   // ai/accent — ✦ icon, AI section labels
    
    // Status / feedback
    static let warning           = "#D97A1E"   // status/warning — AI warning button background
    static let warningText       = "#B35F0F"   // status/warning — warning text
    static let danger            = "#C4342A"   // feedback/danger — delete, disconnect
    static let highlightSearch   = "#F6E2B4"   // highlight/search — search match
    static let scrim             = "#14131252" // scrim — #141312 @ 32%
    
    // Principle bubbles — recency scale (1 = most recent → 5 = oldest)
    static let principle1        = "#EE937B"
    static let principle2        = "#F2B48E"
    static let principle3        = "#E9CF97"
    static let principle4        = "#C9D9A6"
    static let principle5        = "#A9CBB0"
    static let onPrinciple       = "#2A211C"   // label text on bubbles
    
    // Component
    static let disable           = "#C9C2B8"
    static let placeHolder       = "#DCD5C9"
    static let toastBackground   = "#363432"
    static let toastAction       = "#AEB8F0"
    
    static let principleScale = [principle1, principle2, principle3, principle4, principle5]
}

// MARK: Dark
enum DarkColorHex {
    // Background
    static let canvas            = "#141312"
    static let surface           = "#1E1C1B"
    static let sunken            = "#1A1817"
    static let container         = "#262321"
    static let hairline          = "#2E2B28"
    
    // Text
    static let textPrimary       = "#F2EFEA"
    static let textSecondary     = "#A39D96"
    static let textTertiary      = "#7E7871"
    
    // Brand
    static let brandPrimary      = "#AEB8F0"
    static let brandOnPrimary    = "#1A2150"
    static let brandContainer    = "#2F3864"
    static let brandOnContainer  = "#DCE0F4"
    
    // AI
    static let aiTint            = "#221F2E"
    static let aiAccent          = "#B3A8F0"
    
    // Status / feedback
    static let warning           = "#E8973F"
    static let warningText       = "#E8973F"
    static let danger            = "#F0857A"
    static let highlightSearch   = "#5A4A22"
    static let scrim             = "#00000080" // #000000 @ 50%
    
    // Principle bubbles — recency scale (1 = most recent → 5 = oldest)
    static let principle1        = "#C77562"
    static let principle2        = "#C99472"
    static let principle3        = "#BBA676"
    static let principle4        = "#9BAE80"
    static let principle5        = "#82A38A"
    static let onPrinciple       = "#141312"
    
    // Component
    static let disable           = "#4A4640"
    static let placeHolder       = "#2E2B28"
    static let toastBackground   = "#363432"
    static let toastAction       = "#AEB8F0"
    
    static let principleScale = [principle1, principle2, principle3, principle4, principle5]
}

// MARK: - SwiftUI helpers

extension Color {
    /// Creates a color from "#RRGGBB" or "#RRGGBBAA". Invalid input falls back to clear.
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }

        var rgba: UInt64 = 0
        guard Scanner(string: value).scanHexInt64(&rgba), value.count == 6 || value.count == 8 else {
            self = .clear
            return
        }
        if value.count == 6 { rgba = (rgba << 8) | 0xFF }

        self.init(
            .sRGB,
            red:     Double((rgba >> 24) & 0xFF) / 255,
            green:   Double((rgba >> 16) & 0xFF) / 255,
            blue:    Double((rgba >> 8)  & 0xFF) / 255,
            opacity: Double(rgba & 0xFF) / 255
        )
    }

    /// A color that switches between the light and dark hex values with the system appearance.
    static func mpa(_ light: String, dark: String) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
        #else
        return Color(hex: light)
        #endif
    }
    
    static let CANVAS = Color.mpa(LightColorHex.canvas, dark: DarkColorHex.canvas)
    static let SURFACE = Color.mpa(LightColorHex.surface, dark: DarkColorHex.surface)
    static let SUNKEN = Color.mpa(LightColorHex.sunken, dark: DarkColorHex.sunken)
    static let CONTAINER = Color.mpa(LightColorHex.container, dark: DarkColorHex.container)
    static let HAIRLINE = Color.mpa(LightColorHex.hairline, dark: DarkColorHex.hairline)
    static let TEXT_PRIMARY = Color.mpa(LightColorHex.textPrimary, dark: DarkColorHex.textPrimary)
    static let TEXT_SECONDARY = Color.mpa(LightColorHex.textSecondary, dark: DarkColorHex.textSecondary)
    static let TEXT_TERTIARY = Color.mpa(LightColorHex.textTertiary, dark: DarkColorHex.textTertiary)
    static let BRAND_PRIMARY = Color.mpa(LightColorHex.brandPrimary, dark: DarkColorHex.brandPrimary)
    static let BRAND_ON_PRIMARY = Color.mpa(LightColorHex.brandOnPrimary, dark: DarkColorHex.brandOnPrimary)
    static let BRAND_CONTAINER = Color.mpa(LightColorHex.brandContainer, dark: DarkColorHex.brandContainer)
    static let BRAND_ON_CONTAINER = Color.mpa(LightColorHex.brandOnContainer, dark: DarkColorHex.brandOnContainer)
    static let AI_TINT = Color.mpa(LightColorHex.aiTint, dark: DarkColorHex.aiTint)
    static let AI_ACCENT = Color.mpa(LightColorHex.aiAccent, dark: DarkColorHex.aiAccent)
    static let WARNING = Color.mpa(LightColorHex.warning, dark: DarkColorHex.warning)
    static let WARNING_TEXT = Color.mpa(LightColorHex.warningText, dark: DarkColorHex.warningText)
    static let DANGER = Color.mpa(LightColorHex.danger, dark: DarkColorHex.danger)
    static let HIGHLIGHT_SEARCH = Color.mpa(LightColorHex.highlightSearch, dark: DarkColorHex.highlightSearch)
    static let SCRIM = Color.mpa(LightColorHex.scrim, dark: DarkColorHex.scrim)
    static let PRINCIPLE1 = Color.mpa(LightColorHex.principle1, dark: DarkColorHex.principle1)
    static let PRINCIPLE2 = Color.mpa(LightColorHex.principle2, dark: DarkColorHex.principle2)
    static let PRINCIPLE3 = Color.mpa(LightColorHex.principle3, dark: DarkColorHex.principle3)
    static let PRINCIPLE4 = Color.mpa(LightColorHex.principle4, dark: DarkColorHex.principle4)
    static let PRINCIPLE5 = Color.mpa(LightColorHex.principle5, dark: DarkColorHex.principle5)
    static let DISABLE = Color.mpa(LightColorHex.disable, dark: DarkColorHex.disable)
    static let PLACEHOLDER = Color.mpa(LightColorHex.placeHolder, dark: DarkColorHex.placeHolder)
    static let TOAST_BACKGROUND = Color.mpa(LightColorHex.toastBackground, dark: DarkColorHex.toastBackground)
    static let TOAST_ACTION = Color.mpa(LightColorHex.toastAction, dark: DarkColorHex.toastAction)
    static let ON_PRINCIPLE = Color.mpa(LightColorHex.onPrinciple, dark: DarkColorHex.onPrinciple)
    static let PRINCIPLE_SCALES : [Color] = {
#if canImport(UIKit)
        var isDark = false
        
        let _ = Color(UIColor { traits in
            isDark = traits.userInterfaceStyle == .dark
            return UIColor(Color(hex: ""))
        })
        
        return (isDark ? DarkColorHex.principleScale : LightColorHex.principleScale)
            .map({Color(hex: $0)})
#else
return Color(hex: light)
#endif
    }()
}
