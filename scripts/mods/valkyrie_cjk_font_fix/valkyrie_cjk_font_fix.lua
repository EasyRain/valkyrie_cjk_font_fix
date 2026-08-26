-- valkyrie_cjk_font_fix.lua
--
-- Why this mod exists
-- -------------------
-- Valkyrie draws its loading-screen business cards with Gui.slug_text() using
-- hardcoded Latin-only font RESOURCES (content/ui/fonts/proxima_nova_medium,
-- proxima_nova_bold, machine_medium, arial - see valkyrie_business_cards.lua).
-- That low-level call bypasses the UI font pipeline entirely, so any glyph
-- those slug fonts do not contain (CJK, Cyrillic, accented Latin, ...) renders
-- as a box (tofu) - even in a zh-cn/ja/ko locale where the game itself
-- renders CJK fine.
--
-- How the game renders localized text
-- -----------------------------------
-- The UI text pipeline resolves FONT NAMES through the font manager
-- (scripts/managers/ui/ui_font_manager.lua):
--
--   UIFontManager._setup_font_definitions(locale_fonts) builds, for every
--   font name, a .path FALLBACK CHAIN of font resource paths:
--     { base_path..font_name, locale override(s) for the font's type, custom }
--   e.g. for "proxima_nova_medium" in a zh-cn locale:
--     { "content/ui/fonts/proxima_nova_medium",
--       "content/ui/fonts/noto_sans_sc_bold",            <-- CJK!
--       "content/ui/fonts/darktide_custom_regular" }
--
--   UIRenderer.draw_text() -> script_draw_text() resolves the font type via
--   Managers.font:data_by_type(font_type).path and passes that chain to
--   Gui2_slug_text(), which does per-glyph fallback across the chain. That is
--   exactly how the game's own UI renders Chinese in a zh-cn locale.
--
--   IMPORTANT: script_draw_text() requires the trailing "options" argument to
--   be a TABLE (it writes material_flags/flags/color/render_pass into it).
--   Passing nil crashes with "attempt to index local 'additional_settings'".
--
-- How this mod works
-- ------------------
-- It wraps valkyrie's mod._bc.safe_draw_business_card_text() and, while the
-- CJK font extension is active, re-draws strings containing non-Latin
-- characters through UIRenderer.draw_text() passing the ORIGINAL font type
-- name through and a valid (empty) options table. The UI pass then resolves
-- the name against the locale-aware definitions and renders with per-glyph
-- CJK fallback - exactly like the rest of the game's UI.
--
-- Pure ASCII strings always keep the original hardcoded font, so the vanilla
-- look is preserved. When the CJK mod is disabled or missing, everything is
-- left untouched and Valkyrie renders exactly as before.
local mod = get_mod("valkyrie_cjk_font_fix")

local ui_renderer_ok, UIRenderer = pcall(require, "scripts/managers/ui/ui_renderer")
if not ui_renderer_ok then
    UIRenderer = nil
end

local font_definitions_ok, FontDefinitions = pcall(require, "scripts/managers/ui/ui_fonts_definitions")
if not font_definitions_ok then
    FontDefinitions = nil
end

local VALKYRIE_MOD_ID = "valkyrie"
local CJK_MOD_ID = "ShowCnJaKoGlyphsPlus"

-- Constants mirrored from valkyrie_business_cards.lua
local BUSINESS_CARD_LAYER = 80
local BUSINESS_CARD_LINE_HEIGHT = 18
local BUSINESS_CARD_FONT_SIZE = 15
local BUSINESS_CARD_TEXT_COLOR = { 235, 210, 210, 205 }

-- script_draw_text() writes into this table and hands it to Gui2_slug_text(),
-- so it must never be nil. shadow = true keeps the drop shadow Valkyrie's
-- original slug_text call used.
local shared_text_options = { shadow = true }

local original_draw = nil
local logged_draws = 0
local logged_diagnostics = false

local function dbg(fmt, ...)
    if mod:get("debug_logging") then
        mod:info("[dbg] " .. fmt, ...)
    end
end

local function cjk_extension_active()
    local cjk_mod = get_mod(CJK_MOD_ID)
    return cjk_mod ~= nil and cjk_mod:is_enabled()
end

local function contains_non_latin(text)
    if type(text) ~= "string" then
        return false
    end
    -- Anything outside printable ASCII: CJK, Cyrillic, accented Latin, etc.
    return text:find("[^\32-\126]") ~= nil
end

-- Card texts drawn by valkyrie's business cards that are hardcoded English,
-- mapped to localization keys defined in valkyrie_cjk_font_fix_localization.lua
-- so they can follow the game's current language. Covers the fixed labels
-- ("Name:", "Class:", ...) and the fallback values ("None" when e.g. an
-- Arbites has no Blitz selected, "Unknown" when a name/class is missing).
local CARD_TEXT_KEYS = {
    ["Name:"] = "card_label_name",
    ["Class:"] = "card_label_class",
    ["Special Ability:"] = "card_label_special_ability",
    ["Aura:"] = "card_label_aura",
    ["Blitz:"] = "card_label_blitz",
    ["Keystone:"] = "card_label_keystone",
    ["Melee:"] = "card_label_melee",
    ["Ranged:"] = "card_label_ranged",
    ["None"] = "card_value_none",
    ["Unknown"] = "card_value_unknown",
}

-- Shrink the font size if a (translated) label would be wider than its fixed
-- label column. Best effort: any measurement failure keeps the original size.
local function fit_label_font_size(ui_renderer, text, font_type, font_size, max_width)
    local font_path = nil
    if Managers and Managers.font and Managers.font._font_definitions then
        local definition = Managers.font._font_definitions[font_type]
        font_path = definition and definition.path
    end
    local gui = ui_renderer and ui_renderer.gui
    if not (font_path and gui and Gui and Gui.slug_text_extents) then
        return font_size
    end
    local ok, min, max = pcall(Gui.slug_text_extents, gui, text, font_path, font_size)
    if ok and min and max then
        local width = max[1] - min[1]
        if width > max_width and width > 0 then
            return math.max(math.floor(font_size * max_width / width), 8)
        end
    end
    return font_size
end

local function tostring_short(value, max_len)
    max_len = max_len or 160
    local s
    if type(value) == "table" then
        local parts = {}
        for i = 1, math.min(#value, 6) do
            parts[#parts + 1] = tostring(value[i])
        end
        s = "{" .. table.concat(parts, ", ") .. (value[7] and ", ..." or "") .. "}"
    else
        s = tostring(value)
    end
    if #s > max_len then
        s = s:sub(1, max_len) .. "..."
    end
    return s
end

-- Log the resolved font chain the UI pass would use for a font type name.
local function log_font_chain(font_type)
    local locale = "?"
    if Managers and Managers.localization and Managers.localization.language then
        locale = tostring(Managers.localization:language())
    end

    local path_chain = nil
    if Managers and Managers.font and Managers.font._font_definitions then
        local definition = Managers.font._font_definitions[font_type]
        if definition then
            path_chain = definition.path
        end
    end

    dbg("diagnostics: locale=%s cjk_enabled=%s font_type=%s chain=%s",
        locale, tostring(cjk_extension_active()), tostring(font_type), tostring_short(path_chain))
end

local function patched_safe_draw_business_card_text(ui_renderer, text, font_type, x, y, width, options, color, font_size)
    local only_non_latin = mod:get("only_non_latin")
    if only_non_latin == nil then
        only_non_latin = true
    end
    local localize_labels = mod:get("localize_labels")
    if localize_labels == nil then
        localize_labels = true
    end

    -- 1) Translate the fixed card texts (labels like "Name:", fallback values
    -- like "None"/"Unknown") so they follow the game's current language.
    -- Independent of the CJK extension.
    if original_draw and UIRenderer and localize_labels then
        local text_key = CARD_TEXT_KEYS[text]
        if text_key then
            local localized = mod:localize(text_key)
            if localized and localized ~= "" and localized ~= text_key and localized ~= text then
                local draw_font_size = fit_label_font_size(ui_renderer, localized, font_type, font_size or BUSINESS_CARD_FONT_SIZE, width)
                local ok, err = pcall(UIRenderer.draw_text, ui_renderer, localized,
                    draw_font_size,
                    font_type,
                    Vector3(x, y, BUSINESS_CARD_LAYER + 4),
                    Vector2(width, BUSINESS_CARD_LINE_HEIGHT),
                    color or BUSINESS_CARD_TEXT_COLOR,
                    shared_text_options)
                dbg("text: %s -> %s (size=%s) ok=%s err=%s", text, tostring(localized), tostring(draw_font_size), tostring(ok), tostring(err))
                if ok then
                    return
                end
            end
        end
    end

    -- 2) Re-draw strings containing non-Latin characters through the UI text
    -- pass so they render with the locale-aware CJK font chain.
    if original_draw and UIRenderer and only_non_latin and cjk_extension_active() and contains_non_latin(text) then
        if not logged_diagnostics then
            logged_diagnostics = true
            log_font_chain(font_type)
        end

        if logged_draws < 10 then
            logged_draws = logged_draws + 1
            dbg("redirect #%d: font_type=%s text=%s", logged_draws, tostring(font_type), tostring_short(text, 60))
        end

        -- Draw through the UI text pass with the ORIGINAL font type name.
        -- The pass resolves the name via Managers.font:data_by_type() and
        -- draws with per-glyph fallback across the locale-aware chain.
        -- The options argument must be a TABLE (script_draw_text writes into
        -- it), which is exactly the bug in valkyrie's own fallback path.
        local ok, err = pcall(UIRenderer.draw_text, ui_renderer, text,
            font_size or BUSINESS_CARD_FONT_SIZE,
            font_type,
            Vector3(x, y, BUSINESS_CARD_LAYER + 4),
            Vector2(width, BUSINESS_CARD_LINE_HEIGHT),
            color or BUSINESS_CARD_TEXT_COLOR,
            shared_text_options)
        dbg("redirect: draw_text font_type=%s ok=%s err=%s", tostring(font_type), tostring(ok), tostring(err))
        if ok then
            return
        end
    end

    return original_draw(ui_renderer, text, font_type, x, y, width, options, color, font_size)
end

local function business_cards_module()
    local valkyrie = get_mod(VALKYRIE_MOD_ID)
    return valkyrie and valkyrie._bc
end

local original_profile_class_name = nil

-- Valkyrie returns hardcoded English class names for the known archetypes
-- (Veteran, Zealot, Psyker, Ogryn, Arbites, Hive Scum, Skitarius). The game's
-- archetype settings carry a localization key instead (e.g. "loc_class_veteran_name"),
-- which the class selection screen uses. Prefer that official localized name
-- (matches the game's UI in every language), fall back to valkyrie's logic.
local function patched_profile_class_name(profile)
    local localize_labels = mod:get("localize_labels")
    if localize_labels == nil then
        localize_labels = true
    end
    if not localize_labels then
        return original_profile_class_name and original_profile_class_name(profile) or "Unknown"
    end

    local archetype = profile and profile.archetype
    if not archetype then
        return original_profile_class_name and original_profile_class_name(profile) or "Unknown"
    end

    if type(archetype.archetype_name) == "string" and archetype.archetype_name ~= "" then
        local business_cards = business_cards_module()
        local safe_localize = business_cards and business_cards.safe_localize
        if safe_localize then
            local ok, localized = pcall(safe_localize, archetype.archetype_name)
            if ok and localized and localized ~= "None" and localized ~= archetype.archetype_name then
                return localized
            end
        end
    end

    return original_profile_class_name and original_profile_class_name(profile) or "Unknown"
end

local function patch()
    local business_cards = business_cards_module()
    if not business_cards or type(business_cards.safe_draw_business_card_text) ~= "function" then
        return false
    end
    if business_cards.safe_draw_business_card_text ~= patched_safe_draw_business_card_text then
        original_draw = business_cards.safe_draw_business_card_text
        business_cards.safe_draw_business_card_text = patched_safe_draw_business_card_text
    end
    if type(business_cards.profile_class_name) == "function" and business_cards.profile_class_name ~= patched_profile_class_name then
        original_profile_class_name = business_cards.profile_class_name
        business_cards.profile_class_name = patched_profile_class_name
    end
    mod:info("Patched valkyrie business card text rendering.")
    return true
end

local function unpatch()
    local business_cards = business_cards_module()
    if business_cards then
        if business_cards.safe_draw_business_card_text == patched_safe_draw_business_card_text then
            business_cards.safe_draw_business_card_text = original_draw
        end
        if business_cards.profile_class_name == patched_profile_class_name then
            business_cards.profile_class_name = original_profile_class_name
        end
    end
    original_draw = nil
    original_profile_class_name = nil
end

mod.on_all_mods_loaded = function()
    if mod:is_enabled() then
        patch()
    end
end

mod.on_enabled = function(initial_call)
    if not initial_call then
        patch()
    end
end

mod.on_disabled = function()
    unpatch()
end

mod.on_unload = function()
    unpatch()
end
