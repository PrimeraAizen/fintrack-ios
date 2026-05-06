// FinTrack design system — token index (DRD §3, TRD §9)
//
// FTColor      — primary, semantic, neutral (adaptive), category palette
// FTSpacing    — 4-pt grid: s1 (4) … s16 (64)
// FTRadius     — sm (8) … full (999)
// FTTypography — displayXL … numericMD, all with monospacedDigit() for amounts
//
// Rules:
//   • Never use raw .padding(16) — use .padding(FTSpacing.s4)
//   • Never use Color.green     — use FTColor.primary
//   • Adaptive neutrals (bg, surface, border, text*) come from Assets.xcassets
//     and flip automatically between light and dark.
