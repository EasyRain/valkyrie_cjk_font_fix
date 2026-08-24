return {
    mod_name = {
        en = "Valkyrie CJK Font Fix",
        ["zh-cn"] = "瓦尔基里 CJK 字体修复",
        ["zh-tw"] = "瓦爾基里 CJK 字體修復",
        ja = "ヴァルキリー CJK フォント修正",
        ko = "발키리 CJK 폰트 수정",
    },
    mod_description = {
        en = "Fixes boxed (tofu) CJK characters on Valkyrie's loading screen business cards by routing non-Latin text through the CJK font fallback chain installed by Show CJK Glyphs +.",
        ["zh-cn"] = "修复瓦尔基里加载界面名片上中文等字符显示为方框的问题：让含非拉丁字符的文本走 Show CJK Glyphs + 提供的 CJK 字体回退链。",
        ["zh-tw"] = "修復瓦爾基里載入界面名片上中文等字元顯示為方框的問題：讓含非拉丁字元的文字走 Show CJK Glyphs + 提供的 CJK 字體回退鏈。",
        ja = "ヴァルキリーのロード画面の名刺でCJK文字が□（豆腐）表示になる問題を修正します。非ラテン文字を含むテキストを Show CJK Glyphs + が提供するCJKフォールバックフォントチェーン経由で描画します。",
        ko = "발키리의 로딩 화면 명함에서 CJK 문자가 네모(토후)로 표시되는 문제를 수정합니다. 비라틴 문자가 포함된 텍스트를 Show CJK Glyphs +가 제공하는 CJK 폴백 폰트 체인으로 렌더링합니다.",
    },
    only_non_latin = {
        en = "Only redirect non-Latin text",
        ["zh-cn"] = "仅重定向非拉丁文字",
        ["zh-tw"] = "僅重新導向非拉丁文字",
        ja = "非ラテン文字のテキストのみ再描画",
        ko = "비라틴 문자 텍스트만 리다이렉트",
    },
    only_non_latin_description = {
        en = "When enabled, only strings containing non-Latin characters are re-rendered with the CJK-capable fallback font; pure ASCII strings keep Valkyrie's original font.",
        ["zh-cn"] = "启用时，仅包含非拉丁字符的文本改用带 CJK 回退的字体绘制；纯 ASCII 文本保持瓦尔基里原有字体。",
        ["zh-tw"] = "啟用時，僅包含非拉丁字元的文字改用帶 CJK 回退的字體繪製；純 ASCII 文字保持瓦爾基里原有字體。",
        ja = "有効時、非ラテン文字を含む文字列のみCJK対応フォールバックフォントで再描画します。純粋なASCII文字列はヴァルキリーの元のフォントのままです。",
        ko = "활성화하면 비라틴 문자가 포함된 문자열만 CJK 지원 폴백 폰트로 다시 렌더링합니다. 순수 ASCII 문자열은 발키리의 원래 폰트를 유지합니다.",
    },
    debug_logging = {
        en = "Debug logging",
        ["zh-cn"] = "调试日志",
        ["zh-tw"] = "除錯紀錄",
        ja = "デバッグログ",
        ko = "디버그 로깅",
    },
    debug_logging_description = {
        en = "Log diagnostic information (locale, resolved fonts, draw results) to the console log. Turn off once the fix is confirmed working.",
        ["zh-cn"] = "向控制台日志输出诊断信息（语言、解析出的字体、绘制结果）。确认修复生效后可关闭。",
        ["zh-tw"] = "向主控台紀錄輸出診斷資訊（語言、解析出的字體、繪製結果）。確認修復生效後可關閉。",
        ja = "診断情報（言語、解決されたフォント、描画結果）をコンソールログに出力します。修正の動作確認後はオフにしてください。",
        ko = "진단 정보(언어, 해석된 폰트, 렌더링 결과)를 콘솔 로그에 출력합니다. 수정 확인 후에는 끄세요.",
    },
}
