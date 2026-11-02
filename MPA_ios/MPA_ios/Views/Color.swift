//
//  Color.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/2/26.
//

import SwiftUI

enum MPAColor {
    case canvas
    case surface
    case sunken
    case container
    case hairline
    case textPrimary
    case textSecondary
    case textTertiary
    case brandPrimary
    case brandOnPrimary
    case brandContainer
    case brandOnContainer
    case aiTint
    case aiAccent
    case warning
    case warningText
    case danger
    case highlightSearch
    case scrim
    case principle1
    case principle2
    case principle3
    case principle4
    case principle5
    case onPrinciple
    
    var colorHex: String {
        let scheme = Environment(\.colorScheme).wrappedValue
        switch self {
        case .canvas:
            return scheme == .dark ? DarkColorHex.canvas : LightColorHex.canvas
        case .surface:
            return scheme == .dark ? DarkColorHex.surface : LightColorHex.surface
        case .sunken:
            return scheme == .dark ? DarkColorHex.sunken : LightColorHex.sunken
        case .container:
            return scheme == .dark ? DarkColorHex.container : LightColorHex.container
        case .hairline:
            return scheme == .dark ? DarkColorHex.hairline : LightColorHex.hairline
        case .textPrimary:
            return scheme == .dark ? DarkColorHex.textPrimary : LightColorHex.textPrimary
        case .textSecondary:
            return scheme == .dark ? DarkColorHex.textSecondary : LightColorHex.textSecondary
        case .textTertiary:
            return scheme == .dark ? DarkColorHex.textTertiary : LightColorHex.textTertiary
        case .brandPrimary:
            return scheme == .dark ? DarkColorHex.brandPrimary : LightColorHex.brandPrimary
        case .brandOnPrimary:
            return scheme == .dark ? DarkColorHex.brandOnPrimary : LightColorHex.brandOnPrimary
        case .brandContainer:
            return scheme == .dark ? DarkColorHex.brandContainer : LightColorHex.brandContainer
        case .brandOnContainer:
            return scheme == .dark ? DarkColorHex.brandOnContainer : LightColorHex.brandOnContainer
        case .aiTint:
            return scheme == .dark ? DarkColorHex.aiTint : LightColorHex.aiTint
        case .aiAccent:
            return scheme == .dark ? DarkColorHex.aiAccent : LightColorHex.aiAccent
        case .warning:
            return scheme == .dark ? DarkColorHex.warning : LightColorHex.warning
        case .warningText:
            return scheme == .dark ? DarkColorHex.warningText : LightColorHex.warningText
        case .danger:
            return scheme == .dark ? DarkColorHex.danger : LightColorHex.danger
        case .highlightSearch:
            return scheme == .dark ? DarkColorHex.highlightSearch : LightColorHex.highlightSearch
        case .scrim:
            return scheme == .dark ? DarkColorHex.scrim : LightColorHex.scrim
        case .principle1:
            return scheme == .dark ? DarkColorHex.principle1 : LightColorHex.principle1
        case .principle2:
            return scheme == .dark ? DarkColorHex.principle2 : LightColorHex.principle2
        case .principle3:
            return scheme == .dark ? DarkColorHex.principle3 : LightColorHex.principle3
        case .principle4:
            return scheme == .dark ? DarkColorHex.principle4 : LightColorHex.principle4
        case .principle5:
            return scheme == .dark ? DarkColorHex.principle5 : LightColorHex.principle5
        case .onPrinciple:
            return scheme == .dark ? DarkColorHex.onPrinciple : LightColorHex.onPrinciple
        }
    }
}

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
}
