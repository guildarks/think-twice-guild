--[[
    Hasu's Interrupt Tracker — Localization
    Supported locales: enUS, frFR, deDE, itIT, esES, esMX, zhTW, koKR, jaJA, zhCN, ruRU
    English is the default; locale blocks override individual keys.
]]

local locale = GetLocale()

HasuL = {
    -- ── Tracker frame ──────────────────────────────────────────────
    ["TITLE"]            = "Interrupts",
    ["NO_KICK"]          = "No kick available",
    ["READY"]            = "READY",
    ["TOOLTIP_CD"]        = "CD: %.1fs / %.0fs",
    ["TOOLTIP_READY"]     = "READY",
    ["TOOLTIP_ESTIMATED"] = "(estimated — no addon)",

    -- ── Alert band ─────────────────────────────────────────────────
    ["ALERT_ONE_READY"]  = "%s — READY",
    ["ALERT_N_READY"]    = "%d kicks ready  (%s)",
    ["ALERT_INCOMING"]   = "%s in %.1fs",
    ["ALERT_NO_KICK"]    = "NO KICK — %.0fs",

    -- ── Settings window ────────────────────────────────────────────
    ["SETTINGS_TITLE"]   = "Hasu's Interrupt Tracker",
    ["SEC_DISPLAY"]      = "DISPLAY",
    ["SEC_OPTIONS"]      = "OPTIONS",
    ["SEC_APPEARANCE"]   = "APPEARANCE",
    ["SEC_SHOW_IN"]      = "SHOW IN",
    ["SEC_SOUND"]        = "SOUND",
    ["SEC_UI"]           = "UI",
    ["SEC_ROTATION"]     = "ROTATION",

    ["SL_OPACITY"]       = "Opacity: %.0f%%",
    ["SL_WIDTH"]         = "Width: %dpx",
    ["SL_HEIGHT"]        = "Height: %dpx",
    ["SL_NAME_SIZE"]     = "Name Size: %d",
    ["SL_CD_SIZE"]       = "CD Size: %d",
    ["SL_READY_SIZE"]    = "Ready Size: %d",

    ["DD_FONT"]          = "Font: ",
    ["DD_COLOR"]         = "Color: ",
    ["DD_BAR_TEXTURE"]   = "Bar Texture: ",
    ["DD_SOUND"]         = "Sound: ",

    ["CB_SHOW_TITLE"]    = "Show Title",
    ["CB_LOCK_POS"]      = "Lock Position",
    ["CB_SHOW_READY"]    = "Show READY",
    ["CB_KICKS_BAR"]     = "Show 'X kicks ready' bar",
    ["CB_HIDE_OOC"]      = "Hide out of combat",
    ["CB_TOOLTIP"]       = "Tooltip on Hover",
    ["CB_ALERT_CAST"]    = "Alert on interruptible cast",
    ["CB_ROTATION"]      = "Enable Rotation",
    ["DD_MAX_HISTORY"]   = "Run history limit: ",
    ["DD_MAX_HISTORY_TIP"] = "Past runs saved to disk — older ones are deleted once the limit is reached",
    ["ALERT_LOCKED"]     = "LOCKED: %s (%.0fs)",
    ["ALERT_NO_KICK_CAST"] = "!! NO KICK — %s casting !!",
    ["SCORE_TITLE"]      = "All-time Kick Score",
    ["SCORE_RATIO"]      = "Ratio",
    ["BTN_CLEAR"]        = "Clear",
    ["CC_TITLE"]         = "CC Tracker",
    ["CC_NO_CC"]         = "No CC available",
    ["CB_SHOW_CC"]       = "Show CC Tracker",

    ["BTN_SAVE_POS"]     = "Save Position",
    ["BTN_RUN_STATS"]    = "Run Stats",
    ["BTN_COMMANDS"]     = "Commands",
    ["BTN_MANAGE_ROT"]   = "Manage Kick Rotation",

    ["VIS_DUNGEONS"]     = "Dungeons",
    ["VIS_ARENA"]        = "Arena",
    ["VIS_OPEN_WORLD"]   = "Open World",

    ["ROT_MAINTENANCE"]  = "Under Maintenance",

    -- ── Rotation panel ─────────────────────────────────────────────
    ["ROT_TITLE"]        = "Kick Rotation",
    ["ROT_RESET"]        = "Reset",
    ["ROT_SYNC"]         = "Sync Party",
    ["ROT_SYNCED"]       = "Rotation synced to party.",

    -- ── Changelog window ───────────────────────────────────────────

    -- ── Stats window ───────────────────────────────────────────────
    ["STATS_TITLE"]      = "Interrupt Statistics",
    ["STATS_CLEAR"]      = "Clear All",
    ["STATS_ALLTIME"]    = "All-time · %d %s",
    ["STATS_RUN"]        = "run",
    ["STATS_RUNS"]       = "runs",
    ["STATS_CURRENT"]    = "Current Run",
    ["STATS_HISTORY"]    = "History  (%d)",
    ["STATS_NO_KICKS"]   = "No interrupts recorded yet in this run.",
    ["STATS_EMPTY"]      = "No stats yet",
    ["STATS_HINT"]       = "Start a dungeon/arena and interrupt casts to record data.",
    ["STATS_TIP"]        = "Tip: use /loxx test to quickly validate display behavior.",
    ["STATS_KICK"]       = "kick",
    ["STATS_KICKS"]      = "kicks",

    -- ── Save position messages ─────────────────────────────────────
    ["POS_SAVED"]        = "Position saved!",
    ["POS_NO_FRAME"]     = "No frame available to save.",
    ["POS_HIDDEN"]       = "Frame hidden, cannot save position.",

    -- ── Slash command outputs ──────────────────────────────────────
    ["CMD_LOCKED"]       = "Locked",
    ["CMD_UNLOCKED"]     = "Unlocked",
    ["CMD_TEST_ON"]      = "Test mode |cFF00FF00ON|r - 3 fake players. /loxx test to stop.",
    ["CMD_TEST_OFF"]     = "Test mode |cFFFF4444OFF|r",
    ["CMD_HIST_CLEAR"]   = "Run history cleared.",
    ["CMD_LOG_CLEAR"]    = "Error log cleared.",
    ["CMD_NO_LOGS"]      = "No errors recorded.",

    -- ── Kick alert (Rotation Manager priority overlay) ─────────────
    ["KA_P1_LABEL"]      = "KICK NOW",
    ["KA_P2_LABEL"]      = "KICK",
    ["KA_P3_LABEL"]      = "OPTIONAL",
    ["KA_KICKER"]        = "> %s",
    ["KA_MOVE_HINT"]     = "Drag to reposition",
    ["CB_SHOW_NEXT"]     = "Show > (next kicker)",
}

-- ── French ─────────────────────────────────────────────────────────
if locale == "frFR" then
    local T = HasuL
    T["TITLE"]           = "Interruptions"
    T["NO_KICK"]         = "Aucune interruption disponible"
    T["READY"]           = "PRÊT"
    T["TOOLTIP_READY"]   = "PRÊT"
    T["ALERT_ONE_READY"] = "%s — PRÊT"
    T["ALERT_N_READY"]   = "%d interruptions prêtes  (%s)"
    T["ALERT_INCOMING"]  = "%s dans %.1fs"
    T["ALERT_NO_KICK"]   = "AUCUNE INTERR. — %.0fs"
    T["SEC_DISPLAY"]     = "AFFICHAGE"
    T["SEC_OPTIONS"]     = "OPTIONS"
    T["SEC_APPEARANCE"]  = "APPARENCE"
    T["SEC_SHOW_IN"]     = "AFFICHER DANS"
    T["SEC_SOUND"]       = "SON"
    T["SEC_UI"]          = "INTERFACE"
    T["SEC_ROTATION"]    = "ROTATION"
    T["SL_OPACITY"]      = "Opacité : %.0f%%"
    T["SL_WIDTH"]        = "Largeur : %dpx"
    T["SL_HEIGHT"]       = "Hauteur : %dpx"
    T["SL_NAME_SIZE"]    = "Taille nom : %d"
    T["SL_CD_SIZE"]      = "Taille CD : %d"
    T["SL_READY_SIZE"]   = "Taille prêt : %d"
    T["DD_FONT"]         = "Police : "
    T["DD_COLOR"]        = "Couleur : "
    T["DD_BAR_TEXTURE"]  = "Texture barre : "
    T["DD_SOUND"]        = "Son : "
    T["CB_SHOW_TITLE"]   = "Afficher le titre"
    T["CB_LOCK_POS"]     = "Verrouiller la position"
    T["CB_SHOW_READY"]   = "Afficher PRÊT"
    T["CB_KICKS_BAR"]    = "Barre 'X interr. disponibles'"
    T["CB_HIDE_OOC"]     = "Masquer hors combat"
    T["CB_TOOLTIP"]      = "Info-bulle au survol"
    T["CB_ROTATION"]     = "Activer la rotation"
    T["BTN_SAVE_POS"]    = "Sauver position"
    T["BTN_RUN_STATS"]   = "Statistiques"
    T["BTN_COMMANDS"]    = "Commandes"
    T["BTN_MANAGE_ROT"]  = "Gérer la rotation"
    T["VIS_DUNGEONS"]    = "Donjons"
    T["VIS_ARENA"]       = "Arène"
    T["VIS_OPEN_WORLD"]  = "Monde ouvert"
    T["ROT_MAINTENANCE"] = "En maintenance"
    T["ROT_TITLE"]       = "Rotation d'interruptions"
    T["ROT_RESET"]       = "Réinitialiser"
    T["ROT_SYNC"]        = "Sync groupe"
    T["ROT_SYNCED"]      = "Rotation synchronisée avec le groupe."
    T["STATS_TITLE"]     = "Statistiques d'interruptions"
    T["STATS_CLEAR"]     = "Tout effacer"
    T["STATS_ALLTIME"]   = "Total · %d %s"
    T["STATS_RUN"]       = "run"
    T["STATS_RUNS"]      = "runs"
    T["STATS_CURRENT"]   = "Donjon en cours"
    T["STATS_HISTORY"]   = "Historique  (%d)"
    T["STATS_NO_KICKS"]  = "Aucune interruption enregistrée dans ce run."
    T["STATS_EMPTY"]     = "Aucune statistique"
    T["STATS_HINT"]      = "Commence un donjon et interromps des sorts pour enregistrer des données."
    T["STATS_TIP"]       = "Astuce : utilise /loxx test pour valider l'affichage."
    T["STATS_KICK"]      = "interruption"
    T["STATS_KICKS"]     = "interruptions"
    T["POS_SAVED"]       = "Position sauvegardée !"
    T["POS_NO_FRAME"]    = "Aucune fenêtre disponible pour sauvegarder."
    T["POS_HIDDEN"]      = "Fenêtre masquée, impossible de sauvegarder la position."
    T["CMD_LOCKED"]      = "Verrouillé"
    T["CMD_UNLOCKED"]    = "Déverrouillé"
    T["CMD_TEST_ON"]     = "Mode test |cFF00FF00ACTIVÉ|r - 3 joueurs fictifs. /loxx test pour arrêter."
    T["CMD_TEST_OFF"]    = "Mode test |cFFFF4444DÉSACTIVÉ|r"
    T["CMD_HIST_CLEAR"]  = "Historique des runs effacé."
    T["CMD_LOG_CLEAR"]   = "Journal d'erreurs effacé."
    T["CMD_NO_LOGS"]     = "Aucune erreur enregistrée."
    T["KA_P1_LABEL"]     = "KICK MAINTENANT"
    T["KA_P2_LABEL"]     = "KICK"
    T["KA_P3_LABEL"]     = "OPTIONNEL"
    T["KA_KICKER"]       = "> %s"
    T["KA_MOVE_HINT"]    = "Glisser pour déplacer"
    T["CB_SHOW_NEXT"]    = "Afficher > (prochain kicker)"
    T["TOOLTIP_ESTIMATED"]  = "(estimé — pas d'addon)"
    T["CB_ALERT_CAST"]      = "Alerte sur cast interruptible"
    T["DD_MAX_HISTORY"]     = "Limite de l'historique : "
    T["DD_MAX_HISTORY_TIP"] = "Runs sauvegardés — les plus anciens sont supprimés quand la limite est atteinte"
    T["ALERT_LOCKED"]       = "BLOQUÉ : %s (%.0fs)"
    T["ALERT_NO_KICK_CAST"] = "!! AUCUN KICK — %s en train de caster !!"
    T["SCORE_TITLE"]        = "Score de kicks (total)"
    T["SCORE_RATIO"]        = "Ratio"
    T["BTN_CLEAR"]          = "Effacer"
    T["CC_TITLE"]           = "Suivi des CC"
    T["CC_NO_CC"]           = "Aucun CC disponible"
    T["CB_SHOW_CC"]         = "Afficher le suivi CC"
end

-- ── German ──────────────────────────────────────────────────────────

-- ── Italian ─────────────────────────────────────────────────────────

-- ── Spanish ─────────────────────────────────────────────────────────

-- ── Taiwan ─────────────────────────────────────────────────────────

-- ── Korean ──────────────────────────────────────────────────────────

-- ── Japanese ─────────────────────────────────────────────────────────
if locale == "jaJA" then
    local T = HasuL
    T["TITLE"]           = "割り込み"
    T["NO_KICK"]         = "使用可能な割り込みなし"
    T["READY"]           = "準備完了"
    T["TOOLTIP_READY"]   = "準備完了"
    T["ALERT_ONE_READY"] = "%s — 準備完了"
    T["ALERT_N_READY"]   = "%d 割り込み準備完了  (%s)"
    T["ALERT_INCOMING"]  = "%.1f秒後 %s"
    T["ALERT_NO_KICK"]   = "割り込みなし — %.0f秒"
    T["SEC_DISPLAY"]     = "表示"
    T["SEC_OPTIONS"]     = "オプション"
    T["SEC_APPEARANCE"]  = "外観"
    T["SEC_SHOW_IN"]     = "表示場所"
    T["SEC_SOUND"]       = "サウンド"
    T["SEC_UI"]          = "インターフェース"
    T["SL_OPACITY"]      = "不透明度: %.0f%%"
    T["SL_WIDTH"]        = "幅: %dpx"
    T["SL_HEIGHT"]       = "高さ: %dpx"
    T["SL_NAME_SIZE"]    = "名前サイズ: %d"
    T["SL_CD_SIZE"]      = "CDサイズ: %d"
    T["SL_READY_SIZE"]   = "準備サイズ: %d"
    T["DD_FONT"]         = "フォント: "
    T["DD_COLOR"]        = "色: "
    T["DD_BAR_TEXTURE"]  = "バーテクスチャ: "
    T["DD_SOUND"]        = "サウンド: "
    T["CB_SHOW_TITLE"]   = "タイトルを表示"
    T["CB_LOCK_POS"]     = "位置をロック"
    T["CB_SHOW_READY"]   = "準備完了を表示"
    T["CB_KICKS_BAR"]    = "'X 割り込み準備完了' バーを表示"
    T["CB_HIDE_OOC"]     = "戦闘外で非表示"
    T["CB_TOOLTIP"]      = "ホバー時ツールチップ"
    T["BTN_SAVE_POS"]    = "位置を保存"
    T["BTN_RUN_STATS"]   = "割り込み統計"
    T["BTN_COMMANDS"]    = "コマンド"
    T["VIS_DUNGEONS"]    = "ダンジョン"
    T["VIS_ARENA"]       = "アリーナ"
    T["VIS_OPEN_WORLD"]  = "オープンワールド"
    T["STATS_TITLE"]     = "割り込み統計"
    T["STATS_CLEAR"]     = "すべてクリア"
    T["STATS_ALLTIME"]   = "合計 · %d %s"
    T["STATS_RUN"]       = "回"
    T["STATS_RUNS"]      = "回"
    T["STATS_CURRENT"]   = "現在のラン"
    T["STATS_HISTORY"]   = "履歴  (%d)"
    T["STATS_NO_KICKS"]  = "このランの割り込み記録なし。"
    T["STATS_EMPTY"]     = "統計なし"
    T["STATS_HINT"]      = "ダンジョンを開始してキャストを割り込みしてデータを記録してください。"
    T["STATS_TIP"]       = "ヒント: /loxx test で表示動作を確認できます。"
    T["STATS_KICK"]      = "割り込み"
    T["STATS_KICKS"]     = "割り込み"
    T["POS_SAVED"]       = "位置を保存しました！"
    T["POS_NO_FRAME"]    = "保存するフレームがありません。"
    T["POS_HIDDEN"]      = "フレームが非表示のため位置を保存できません。"
    T["CMD_LOCKED"]      = "ロック済み"
    T["CMD_UNLOCKED"]    = "ロック解除"
    T["CMD_TEST_ON"]     = "テストモード |cFF00FF00オン|r - 偽プレイヤー3人。/loxx test で停止。"
    T["CMD_TEST_OFF"]    = "テストモード |cFFFF4444オフ|r"
    T["CMD_HIST_CLEAR"]  = "ラン履歴をクリアしました。"
    T["CMD_LOG_CLEAR"]   = "エラーログをクリアしました。"
    T["CMD_NO_LOGS"]     = "エラーの記録なし。"
    T["SEC_ROTATION"]       = "ローテーション"
    T["CB_ROTATION"]        = "ローテーション有効化"
    T["BTN_MANAGE_ROT"]     = "割り込みローテーション管理"
    T["ROT_MAINTENANCE"]    = "メンテナンス中"
    T["ROT_TITLE"]          = "割り込みローテーション"
    T["ROT_RESET"]          = "リセット"
    T["ROT_SYNC"]           = "グループ同期"
    T["ROT_SYNCED"]         = "ローテーションをグループと同期しました。"
    T["KA_P1_LABEL"]        = "今すぐ割り込み"
    T["KA_P2_LABEL"]        = "割り込み"
    T["KA_P3_LABEL"]        = "任意"
    T["KA_KICKER"]          = "> %s"
    T["KA_MOVE_HINT"]       = "ドラッグして移動"
    T["CB_SHOW_NEXT"]       = "> (次のキッカー) 表示"
    T["TOOLTIP_ESTIMATED"]  = "(推定 — アドオンなし)"
    T["CB_ALERT_CAST"]      = "割り込み可能キャスト時アラート"
    T["DD_MAX_HISTORY"]     = "履歴上限: "
    T["DD_MAX_HISTORY_TIP"] = "保存されたRun — 上限に達すると古いものが削除されます"
    T["ALERT_LOCKED"]       = "ロック: %s (%.0f秒)"
    T["ALERT_NO_KICK_CAST"] = "!! 割り込みなし — %s がキャスト中 !!"
    T["SCORE_TITLE"]        = "全体割り込みスコア"
    T["SCORE_RATIO"]        = "比率"
    T["BTN_CLEAR"]          = "クリア"
    T["CC_TITLE"]           = "CC追跡"
    T["CC_NO_CC"]           = "使用可能なCCなし"
    T["CB_SHOW_CC"]         = "CCトラッカーを表示"
end

-- ── Simplified Chinese ────────────────────────────────────────────────

-- ── Russian ──────────────────────────────────────────────────────────
