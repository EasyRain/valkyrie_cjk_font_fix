-- valkyrie_cjk_font_fix
-- Companion patch for the "valkyrie" mod: makes its loading screen business
-- cards use the CJK-capable font fallback chain installed by
-- "Show CJK Glyphs +" (ShowCnJaKoGlyphsPlus).
return {
    run = function()
        fassert(rawget(_G, "new_mod"), "`valkyrie_cjk_font_fix` needs Darktide Mod Framework.")
        new_mod("valkyrie_cjk_font_fix", {
            mod_script       = "valkyrie_cjk_font_fix/scripts/mods/valkyrie_cjk_font_fix/valkyrie_cjk_font_fix",
            mod_data         = "valkyrie_cjk_font_fix/scripts/mods/valkyrie_cjk_font_fix/valkyrie_cjk_font_fix_data",
            mod_localization = "valkyrie_cjk_font_fix/scripts/mods/valkyrie_cjk_font_fix/valkyrie_cjk_font_fix_localization",
        })
    end,
    packages = {},
    version = "1.7.0",
}
