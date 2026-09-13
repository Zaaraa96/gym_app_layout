# CueLift design system

Brand identity and UI tokens for the gym app. Product name: **CueLift**.

## Brand core

Primary identity is the **Welcome-style brand stack**:

1. Slash-tail **C** mark (coral on navy)
2. Wordmark **CueLift** — `Cue` white / `Lift` coral
3. One line: *Your training assistant*

| Surface | Treatment |
|---|---|
| Welcome / splash | Full Welcome stack on navy `#0B1D36` (always — light or dark preference does not change this) |
| Plans app bar | Small C icon + screen title |
| Live workout | No logo; coral only on primary actions |
| Launcher icon | Slash-tail C on navy |

### Logo rules

- Keep the slash-tail angle fixed.
- Do not stretch, outline, or recolor `Lift` to white on the navy lockup.
- Clear space around the mark ≈ the C stroke width.

## Color

| Token | Hex | Role |
|---|---|---|
| `navy` | `#0B1D36` | Brand field, Welcome/splash, dark app chrome seed |
| `coral` | `#FF4D3D` | Primary CTA, active nav, Lift, accents |
| `white` | `#FFFFFF` | Text on navy, on-primary |
| `surface` | `#F4F6FA` | Light scaffold |
| `surfaceElevated` | `#FFFFFF` | Light cards |
| `text` | `#0B1D36` | Primary text on light |
| `textMuted` | `#6B7280` | Subtitles / meta (light) |
| `darkSurface` | `#121826` | Dark scaffold |
| `darkElevated` | `#1A2336` | Dark cards |
| `textMutedDark` | `#9AA3B2` | Subtitles on dark |
| `outline` | `#D7DCE5` | Light borders |
| `outlineDark` | `#2A3448` | Dark borders |
| `success` | `#22C55E` | Done / saved |
| `warning` | `#F59E0B` | Draft / attention |
| `error` | `#EF4444` | Destructive (use sparingly next to coral) |

**Rules**

- One coral hit per focused view (usually the main CTA).
- Navy + coral is the brand pair; do not add a third brand hue.
- Coral stays the accent in both light and dark themes.

## Light / dark themes

| Role | Light | Dark |
|---|---|---|
| Scaffold | `#F4F6FA` | `#121826` |
| Cards / sheets | `#FFFFFF` | `#1A2336` |
| Primary text | `#0B1D36` | `#FFFFFF` |
| Muted text | `#6B7280` | `#9AA3B2` |
| Accent / CTA | `#FF4D3D` | `#FF4D3D` |
| On accent | `#FFFFFF` | `#FFFFFF` |
| Borders | `#D7DCE5` | `#2A3448` |
| C mark in chrome | Coral | Coral |

Welcome and native splash stay on the navy brand field in both modes.

## Typography

Geometric grotesque direction (system / Material defaults acceptable until a bundled font ships).

| Role | Size / weight | Example |
|---|---|---|
| Display | 40–48 · Bold | CueLift on Welcome |
| Headline | 28–32 · Semibold | Your training assistant |
| Title | 20–22 · Semibold / w900 app titles | Plans, Month |
| Body | 16 · Regular / Medium | Supporting copy |
| Label | 12–13 · Medium | SET 2 OF 3 |
| Button | 16 · Semibold | Start workout |

Wordmark spelling is always `CueLift` (no space). Color split only on navy.

## Layout

| Token | Value |
|---|---|
| Base unit | `4` |
| Page gutter | `20` (see `AppScaffold`) |
| Section gap | `24–32` |
| Card radius | `12–16` (interaction containers) |
| Button radius | `12` |
| App-bar mark | `28` |

Welcome: one vertical composition — brand stack → actions. No cards in the hero.

## Components

| Component | Spec |
|---|---|
| Primary button | Coral fill, white label |
| Secondary / outlined | On navy Welcome: white outline; on light/dark surfaces: coral or outline variant |
| App bar | Surface + title; leading C on Plans home |
| Bottom / nav | Active = coral |
| Chips (Draft) | Warning tint |
| Live workout | No brand mark |

## Motion

1. Welcome brand stack appears once on entry (~400ms).
2. Primary CTA: light scale on press.
3. Tab / active: coral indicator ease.

No glow pulses.

## Assets

| File | Use |
|---|---|
| `assets/image/brand/cuelift-welcome.png` | Welcome / splash Flutter brand |
| `assets/image/brand/cuelift-icon.png` | Launcher + app-bar mark source |
| `assets/image/brand/cuelift-lockup.png` | Optional horizontal lockup |
| `assets/image/brand/cuelift-mark-light.png` | Coral C on light UI |

Platform launcher icons and iOS launch images are generated from `cuelift-icon.png`.

## Implementation map

| Code | Responsibility |
|---|---|
| `lib/common/app_theme.dart` | Light / dark `ThemeData` + CueLift color tokens |
| `lib/features/welcome/welcome_page.dart` | Welcome rule brand field |
| `lib/app/app_bootstrap.dart` | Boot splash uses Welcome brand |
| `lib/features/plans/plans_home_page.dart` | App-bar C mark |
| Native Android / iOS splash + mipmaps | Navy field + C icon |
