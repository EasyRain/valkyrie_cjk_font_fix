# Valkyrie CJK Font Fix

A small companion patch for the Darktide mod **[Valkyrie](https://www.nexusmods.com/warhammer40kdarktide/mods/)** that fixes boxed (tofu) characters on Valkyrie's loading-screen business cards.

## Problem

Valkyrie draws its business-card text with `Gui.slug_text()` using **hardcoded Latin-only font resources** (`proxima_nova_medium`, `proxima_nova_bold`, `machine_medium`, `arial`). That low-level call bypasses the UI font definitions, so any glyph those fonts don't contain — Chinese, Japanese, Korean, Cyrillic, accented Latin — renders as a box, **even when a CJK font patch (e.g. "Show CJK Glyphs +") is installed**.

## Solution

The game renders localized text by resolving **font names** through the font manager: for every font name, `UIFontManager._setup_font_definitions()` builds a `.path` **fallback chain** of font resource paths (e.g. for `proxima_nova_medium` in `zh-cn`: `content/ui/fonts/proxima_nova_medium` → `content/ui/fonts/noto_sans_sc_bold` → custom font). `UIRenderer.draw_text()` resolves the name through `Managers.font:data_by_type()` and the engine does per-glyph fallback across that chain — that is exactly how the game's own UI renders Chinese. Valkyrie bypasses this entire chain by handing `Gui.slug_text()` a raw resource path.

While the CJK font extension **Show CJK Glyphs +** (`ShowCnJaKoGlyphsPlus`) is active, this mod re-routes business-card strings that contain non-Latin characters through `UIRenderer.draw_text()` **passing the original font type name through plus a valid options table** — the UI pass then resolves the name against the locale-aware definitions and renders with per-glyph CJK fallback, exactly like the rest of the game's UI.

*(Note: `UIRenderer.draw_text()` requires its trailing `options` argument to be a table — the renderer writes flags/color into it. Valkyrie's own internal `draw_text` fallback passes `nil` and would crash if it ever ran; this mod passes a proper table.)*

Pure ASCII strings keep Valkyrie's original font, so the vanilla look is preserved. When the CJK mod is disabled or missing, this mod does nothing and Valkyrie behaves exactly as before.

## Requirements

- Darktide Mod Framework (DMF)
- [Valkyrie](https://www.nexusmods.com/warhammer40kdarktide/mods/) mod
- [Show CJK Glyphs +](https://www.nexusmods.com/warhammer40kdarktide/mods/1113) (or the original [Show CJK Glyphs](https://www.nexusmods.com/warhammer40kdarktide/mods/149))

## Installation

1. Copy the `valkyrie_cjk_font_fix` folder into your game's `mods` folder:
   `<Steam>\steamapps\common\Warhammer 40,000 DARKTIDE\mods\`
2. Add `valkyrie_cjk_font_fix` to `mods\mod_load_order.txt` (anywhere after `valkyrie`).
3. Enable the mod in the Darktide Mod Framework mod menu (Mods → Valkyrie CJK Font Fix → Enabled).

## Options

| Setting | Default | Description |
| --- | --- | --- |
| Only redirect non-Latin text | On | When enabled, only strings containing non-Latin characters are re-rendered with the CJK-capable fallback font; pure ASCII strings keep Valkyrie's original font. Turn off to re-render all card text with the fallback font. |
| Localize card labels | On | Translate the card labels (Name:, Class:, Special Ability:, Aura:, Blitz:, Keystone:, Melee:, Ranged:) to follow the game's current language. Supported: EN, FR, DE, IT, ES, PL, PT-BR, RU, JA, KO, ZH-CN, ZH-TW. Labels wider than their column are automatically downscaled to fit. |
| Debug logging | Off | Log diagnostic information (locale, resolved font chains, draw results) to the console log. Only needed for troubleshooting. |

## Notes

- This patch wraps `mod._bc.safe_draw_business_card_text` from Valkyrie's business-cards module at load time. If you hot-reload Valkyrie through DMF while playing, toggle this mod off and on again (or restart the game) to re-apply the patch.
- The card class icons (drawn via `machine_medium` UIWidget) are unaffected.
- Load order is irrelevant: the patch is applied in the DMF `on_all_mods_loaded` phase, after every mod has loaded.

## License

MIT
