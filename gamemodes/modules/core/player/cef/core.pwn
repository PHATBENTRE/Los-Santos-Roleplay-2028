#include <YSI_Coding\y_hooks>

hook OnGameModeInit()
{
    CEF_AddResource("lsrp");
    CEF_RegisterEvent("lsrp:ready", "LSRP_UIReady");
    CEF_RegisterEvent("lsrp:submit", "LSRP_UISubmit", Argument_String);
    CEF_RegisterEvent("lsrp:back", "LSRP_UIBack");
    CEF_RegisterEvent("lsrp:slot", "LSRP_UISlot", Argument_Integer);
    CEF_RegisterEvent("lsrp:play", "LSRP_UIPlay");
    CEF_RegisterEvent("lsrp:classic", "LSRP_UIClassic");
    CEF_RegisterEvent("lsrp:notify_drained", "LSRP_UINotifyDrained");
    CEF_RegisterEvent("lsrp:creator_confirm", "LSRP_CreatorConfirm", Argument_String,
        Argument_Integer, Argument_Integer, Argument_Integer, Argument_Integer,
        Argument_Integer, Argument_Integer, Argument_Integer, Argument_Integer, Argument_Integer);
    return 1;
}

forward LSRP_UIRender(playerid);
public LSRP_UIRender(playerid)
{
    if (!UI_UseCEF(playerid) || !s_CefLoaded[playerid]) return 0;
    new username[ACCOUNT_USERNAME_LENGTH];
    GetPlayerAccountUsername(playerid, username, sizeof username);
    CEF_EmitEvent(playerid, LSRP_BROWSER, "lsrp:screen", CEF_INT(s_UIStage[playerid]), CEF_STR(username));
    if (s_UIStage[playerid] == UI_SLOTS)
    {
        for (new i; i < MAX_CHARACTER_SLOTS; i++)
        {
            CEF_EmitEvent(playerid, LSRP_BROWSER, "lsrp:character", CEF_INT(i),
                CEF_STR(s_CharacterSlotName[playerid][i]), CEF_INT(s_CharacterSlotLevel[playerid][i]),
                CEF_INT(s_CharacterSlotSkin[playerid][i]), CEF_BOOL(s_CharacterSlotID[playerid][i] != INVALID_CHARACTER_ID),
                CEF_BOOL(s_SelectedCharacterSlot[playerid] == i + 1));
        }
    }
    UI_SendSnapshot(playerid);
    return 1;
}

// ReSA can deliver browser -> Pawn while failing to deliver EmitBrowserEvent
// back to JS. Mirror non-secret UI state through the supported LoadUrl command.
// Identical snapshots are not navigated again: page-ready cannot form a loop.
stock UI_SendSnapshot(playerid)
{
    new username[ACCOUNT_USERNAME_LENGTH], url[768], slotData[160];
    GetPlayerAccountUsername(playerid, username, sizeof username);
    format(url, sizeof url, "http://cef/lsrp/index.html?v=4#ui=1&stage=%d&rev=%d&username=%s&selected=%d&error=%d",
        s_UIStage[playerid], s_UIRevision[playerid], username, s_SelectedCharacterSlot[playerid], s_UIError[playerid]);
    if (s_UIToastRevision[playerid] > 0 && s_UIToastUntil[playerid] > GetTickCount())
    {
        format(slotData, sizeof slotData, "&toast=%d", s_UIToastRevision[playerid]);
        strcat(url, slotData, sizeof url);
    }
    if (s_UIStage[playerid] == UI_SLOTS)
    {
        for (new slot; slot < MAX_CHARACTER_SLOTS; slot++)
        {
            // Valid character names only contain ASCII letters and underscore.
            if (s_CharacterSlotID[playerid][slot] != INVALID_CHARACTER_ID &&
                !IsValidCharacterName(s_CharacterSlotName[playerid][slot])) continue;
            format(slotData, sizeof slotData, "&n%d=%s&l%d=%d&k%d=%d&e%d=%d", slot,
                s_CharacterSlotName[playerid][slot], slot, s_CharacterSlotLevel[playerid][slot],
                slot, s_CharacterSlotSkin[playerid][slot], slot,
                s_CharacterSlotID[playerid][slot] != INVALID_CHARACTER_ID);
            strcat(url, slotData, sizeof url);
        }
    }
    if (s_UIStage[playerid] == UI_CREATOR)
    {
        format(slotData, sizeof slotData, "&cbusy=%d&cactive=%d&cname=%s",
            s_UICreatorPending[playerid], CharacterCreator_IsActive(playerid),
            CharacterCreator_IsActive(playerid) ? s_CharacterName[playerid] : s_UICreatorName[playerid]);
        strcat(url, slotData, sizeof url);
        if (CharacterCreator_IsActive(playerid))
        {
            format(slotData, sizeof slotData, "&cg=%d&cd=%d&cm=%d&cy=%d&ct=%d&cv=%d&ch=%d&cw=%d&cb=%d",
                s_CharacterGender[playerid], s_CharacterBirthDay[playerid], s_CharacterBirthMonth[playerid],
                s_CharacterBirthYear[playerid], s_CharacterSkinTone[playerid], s_CharacterVoice[playerid],
                s_CharacterHeight[playerid], s_CharacterWeight[playerid], s_CharacterBirthPlace[playerid]);
            strcat(url, slotData, sizeof url);
        }
    }
    if (!strcmp(url, s_UILastURL[playerid])) return 1;
    format(s_UILastURL[playerid], 768, "%s", url);
    CEF_LoadUrl(playerid, LSRP_BROWSER, url);
    return 1;
}

stock UI_ReportError(playerid, code, const message[])
{
    s_UIError[playerid] = code;
    s_UIRevision[playerid]++;
    CEF_EmitEvent(playerid, LSRP_BROWSER, "lsrp:error", CEF_STR(message));
    UI_Notify(playerid, "error", message);
    UI_SendSnapshot(playerid);
    return 1;
}

stock bool:UI_Action(playerid)
{
    if (!IsPlayerConnected(playerid) || !UI_UseCEF(playerid) || !s_CefLoaded[playerid]) return false;
    new now = GetTickCount();
    if (now - s_CefLastAction[playerid] < 400)
    {
        LSRP_UIRender(playerid);
        return false;
    }
    s_CefLastAction[playerid] = now;
    return true;
}

forward LSRP_UIReady(playerid, browserid);
public LSRP_UIReady(playerid, browserid)
{
    if (browserid != LSRP_BROWSER) return 0;
    if (!s_CefBrowser[playerid] || !UI_UseCEF(playerid)) return 0;
    s_CefLoaded[playerid] = true;
    if (!s_UIStage[playerid]) return 1;
    CEF_SetBrowserVisible(playerid, LSRP_BROWSER, true);
    CEF_FocusBrowser(playerid, LSRP_BROWSER, true);
    return LSRP_UIRender(playerid);
}

forward LSRP_UINotifyDrained(playerid, browserid);
public LSRP_UINotifyDrained(playerid, browserid)
{
    if (browserid != LSRP_BROWSER || !IsPlayerConnected(playerid) || s_UIStage[playerid] != 0)
        return 0;
    if (s_CefBrowser[playerid]) CEF_SetBrowserVisible(playerid, LSRP_BROWSER, false);
    return 1;
}

forward LSRP_UISubmit(playerid, browserid, const value[]);
public LSRP_UISubmit(playerid, browserid, const value[])
{
    if (browserid != LSRP_BROWSER) return 0;
    if (!UI_Action(playerid) || IsPlayerLoggedIn(playerid)) return 0;
    new dialogid;
    switch (s_UIStage[playerid])
    {
        case UI_USERNAME: dialogid = DIALOG_ACCOUNT_USERNAME;
        case UI_REGISTER: dialogid = DIALOG_REGISTRATION;
        case UI_LOGIN: dialogid = DIALOG_LOGIN;
        default: return 0;
    }
    if (strlen(value) > 72)
    {
        UI_ReportError(playerid, 3, "Toi da 72 ky tu.");
        return 0;
    }
    new input[73];
    if ((s_UIStage[playerid] == UI_USERNAME && !IsValidAccountUsername(value)) ||
        (s_UIStage[playerid] == UI_REGISTER && !IsValidPassword(value)))
    {
        UI_ReportError(playerid, 1, "Ten dang nhap: 3-24 ky tu chu/so/_. Mat khau: 6-72 ky tu.");
        return 0;
    }
    format(input, sizeof input, "%s", value);
    Account_HandleResponse(playerid, dialogid, 1, 0, input);
    s_UIRevision[playerid]++;
    LSRP_UIRender(playerid);
    return 1;
}

forward LSRP_UIBack(playerid, browserid);
public LSRP_UIBack(playerid, browserid)
{
    if (browserid != LSRP_BROWSER) return 0;
    if (!UI_Action(playerid) || IsPlayerLoggedIn(playerid)) return 0;
    if (s_UIStage[playerid] != UI_LOGIN && s_UIStage[playerid] != UI_REGISTER) return 0;
    DeletePVar(playerid, "tempPassword");
    Account_ShowUsernameDialog(playerid);
    return 1;
}

forward LSRP_UISlot(playerid, browserid, slot);
public LSRP_UISlot(playerid, browserid, slot)
{
    if (browserid != LSRP_BROWSER) return 0;
    if (!UI_Action(playerid) || s_UIStage[playerid] != UI_SLOTS || !IsPlayerLoggedIn(playerid) || s_CharacterLoaded[playerid]) return 0;
    return CharacterSelector_SelectSlot(playerid, slot);
}

forward LSRP_UIPlay(playerid, browserid);
public LSRP_UIPlay(playerid, browserid)
{
    if (browserid != LSRP_BROWSER) return 0;
    if (!UI_Action(playerid) || s_UIStage[playerid] != UI_SLOTS || !IsPlayerLoggedIn(playerid) || s_CharacterLoaded[playerid]) return 0;
    return CharacterSelector_Play(playerid);
}

stock UI_CreatorFail(playerid, code)
{
    if (!s_UICreatorPending[playerid] && s_UIError[playerid] == code) return 1;
    if (code == 8) printf("[GTASA UI] creator save failed player=%d", playerid);
    s_UICreatorPending[playerid] = false;
    s_CreatorSaving[playerid] = false;
    s_UIError[playerid] = code;
    s_UIRevision[playerid]++;
    return UI_SendSnapshot(playerid);
}

stock bool:UI_CreatorRequestValid(playerid, session, request)
{
    return IsPlayerConnected(playerid) && IsPlayerLoggedIn(playerid) &&
        s_UISession[playerid] == session && s_UICreatorRequest[playerid] == request &&
        s_UICreatorPending[playerid];
}

forward LSRP_CreatorConfirm(playerid, browserid, const name[], gender, day, month, year, tone, voice, height, weight, birthplace);
public LSRP_CreatorConfirm(playerid, browserid, const name[], gender, day, month, year, tone, voice, height, weight, birthplace)
{
    if (browserid != LSRP_BROWSER || !IsPlayerLoggedIn(playerid) || !UI_UseCEF(playerid) ||
        s_UIStage[playerid] != UI_CREATOR) return 0;
    if (s_UICreatorPending[playerid]) return UI_SendSnapshot(playerid);
    if (!IsValidCharacterName(name)) return UI_CreatorFail(playerid, 5);
    // Accept any calendar year (no roleplay age restriction).
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1 ||
        day > Creator_GetDaysInMonth(month, year)) return UI_CreatorFail(playerid, 6);
    if (gender < 0 || gender > 1 || tone < 0 || tone > 2 || voice < 0 || voice > 3 ||
        height < 150 || height > 210 || weight < 45 || weight > 150 || birthplace < 0 || birthplace > 3)
        return UI_CreatorFail(playerid, 7);
    new slot = s_SelectedCharacterSlot[playerid];
    if (slot < 1 || slot > MAX_CHARACTER_SLOTS ||
        (s_CharacterLoaded[playerid] && (!s_CreatorActive[playerid] || s_CharacterCreated[playerid])))
        return UI_CreatorFail(playerid, 9);
    if (s_CreatorActive[playerid] && strcmp(name, s_CharacterName[playerid]))
        return UI_CreatorFail(playerid, 9);

    s_UICreatorProfile[playerid][cpGender] = gender;
    s_UICreatorProfile[playerid][cpDay] = day;
    s_UICreatorProfile[playerid][cpMonth] = month;
    s_UICreatorProfile[playerid][cpYear] = year;
    s_UICreatorProfile[playerid][cpTone] = tone;
    s_UICreatorProfile[playerid][cpVoice] = voice;
    s_UICreatorProfile[playerid][cpHeight] = height;
    s_UICreatorProfile[playerid][cpWeight] = weight;
    s_UICreatorProfile[playerid][cpBirthplace] = birthplace;
    format(s_UICreatorName[playerid], 25, "%s", name);
    s_UICreatorSlot[playerid] = slot;
    s_UICreatorPending[playerid] = true;
    s_UICreatorRequest[playerid]++;
    s_UIError[playerid] = 0;
    s_UIRevision[playerid]++;
    UI_SendSnapshot(playerid);
    SetTimerEx("LSRP_CreatorTimeout", 12000, false, "ddd", playerid, s_UISession[playerid], s_UICreatorRequest[playerid]);

    if (s_CreatorActive[playerid])
    {
        s_CharacterGender[playerid] = gender;
        s_CharacterBirthDay[playerid] = day;
        s_CharacterBirthMonth[playerid] = month;
        s_CharacterBirthYear[playerid] = year;
        s_CharacterSkinTone[playerid] = tone;
        s_CharacterVoice[playerid] = voice;
        s_CharacterHeight[playerid] = height;
        s_CharacterWeight[playerid] = weight;
        s_CharacterBirthPlace[playerid] = birthplace;
        s_CreatorSkinIndex[playerid] = random(CREATOR_SKINS_PER_GROUP);
        Creator_ApplySkin(playerid);
        return CharacterCreator_Confirm(playerid);
    }

    new query[256];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "SELECT `character_id` FROM `player_characters` WHERE `name`='%e' OR (`account_id`=%d AND `slot`=%d) LIMIT 1;",
        name, GetPlayerAccountID(playerid), slot);
    if (!mysql_tquery(g_DatabaseHandle, query, "LSRP_CreatorNameChecked", "ddd", playerid,
        s_UISession[playerid], s_UICreatorRequest[playerid])) return UI_CreatorFail(playerid, 8);
    return 1;
}

forward LSRP_CreatorNameChecked(playerid, session, request);
public LSRP_CreatorNameChecked(playerid, session, request)
{
    if (!UI_CreatorRequestValid(playerid, session, request)) return 0;
    if (cache_num_rows()) return UI_CreatorFail(playerid, 4);
    new query[1200];
    new skin = g_CreatorSkins[s_UICreatorProfile[playerid][cpGender]][s_UICreatorProfile[playerid][cpTone]][random(CREATOR_SKINS_PER_GROUP)];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "INSERT IGNORE INTO `player_characters` (`account_id`,`slot`,`name`,`skin`,`cash`,`bank`,`level`,`health`,`armour`,`pos_x`,`pos_y`,`pos_z`,`pos_a`,`interior_id`,`virtual_world`,`character_created`,`gender`,`birth_day`,`birth_month`,`birth_year`,`skin_tone`,`voice`,`height_cm`,`weight_kg`,`birth_place`) VALUES (%d,%d,'%e',%d,%d,%d,%d,100.0,0.0,%f,%f,%f,%f,0,0,1,%d,%d,%d,%d,%d,%d,%d,%d,%d);",
        GetPlayerAccountID(playerid), s_UICreatorSlot[playerid], s_UICreatorName[playerid], skin,
        DEFAULT_CHARACTER_CASH, DEFAULT_CHARACTER_BANK, DEFAULT_CHARACTER_LEVEL,
        GANTON_SPAWN_X, GANTON_SPAWN_Y, GANTON_SPAWN_Z, GANTON_SPAWN_A,
        s_UICreatorProfile[playerid][cpGender], s_UICreatorProfile[playerid][cpDay], s_UICreatorProfile[playerid][cpMonth],
        s_UICreatorProfile[playerid][cpYear], s_UICreatorProfile[playerid][cpTone], s_UICreatorProfile[playerid][cpVoice],
        s_UICreatorProfile[playerid][cpHeight], s_UICreatorProfile[playerid][cpWeight], s_UICreatorProfile[playerid][cpBirthplace]);
    if (!mysql_tquery(g_DatabaseHandle, query, "LSRP_CreatorInserted", "ddd", playerid, session, request))
        return UI_CreatorFail(playerid, 8);
    return 1;
}

forward LSRP_CreatorInserted(playerid, session, request);
public LSRP_CreatorInserted(playerid, session, request)
{
    if (!UI_CreatorRequestValid(playerid, session, request)) return 0;
    new id = cache_insert_id();
    if (id <= 0 || cache_affected_rows() != 1) return UI_CreatorFail(playerid, 4);
    // Keep cbusy set until the character load finishes; the UI must not submit twice.
    return Character_LoadByID(playerid, id);
}

forward LSRP_CreatorTimeout(playerid, session, request);
public LSRP_CreatorTimeout(playerid, session, request)
{
    if (!UI_CreatorRequestValid(playerid, session, request)) return 0;
    return UI_CreatorFail(playerid, 8);
}

forward LSRP_UIClassic(playerid, browserid);
public LSRP_UIClassic(playerid, browserid)
{
    if (browserid != LSRP_BROWSER || !IsPlayerConnected(playerid)) return 0;
    return UI_Classic(playerid);
}

UI_Classic(playerid)
{
    if (s_UICreatorPending[playerid]) return 0;
    new stage = s_UIStage[playerid];
    UI_Close(playerid);
    s_CefClassic[playerid] = true;
    switch (stage)
    {
        case UI_USERNAME: Account_ShowUsernameDialog(playerid);
        case UI_REGISTER: Account_ShowRegistrationDialog(playerid);
        case UI_LOGIN: Account_ShowLoginDialog(playerid);
        case UI_SLOTS: CharacterSelector_OpenUI(playerid);
        case UI_BUSY: s_UIStage[playerid] = UI_BUSY;
        case UI_CREATOR:
        {
            if (s_CreatorActive[playerid]) Creator_ShowUI(playerid);
            else Character_ShowNameDialog(playerid);
        }
    }
    return 1;
}

public OnCefReady(playerid)
{
    s_CefReady[playerid] = true;
    // Upgrade only an idle username prompt; never interrupt a database request or creator.
    if (s_UIStage[playerid] == UI_USERNAME && !IsPlayerLoggedIn(playerid)) UI_Show(playerid, UI_USERNAME);
    return 1;
}

public OnCefInitialize(playerid, bool:success, E_CEF_INIT_REASON:reason, const message[])
{
    if (!success)
    {
        printf("[LSRP CEF] player=%d handshake failed reason=%d: %s", playerid, _:reason, message);
        if (s_CefReady[playerid]) UI_Classic(playerid);
        s_CefReady[playerid] = false;
    }
    return 1;
}

public OnCefBrowserCreated(playerid, browserid, bool:success, E_CEF_CREATE_STATUS:code, const reason[])
{
    #pragma unused code, reason
    if (browserid == LSRP_BROWSER && !success) UI_Classic(playerid);
    return 1;
}

forward LSRP_UILoadTimeout(playerid, session);
public LSRP_UILoadTimeout(playerid, session)
{
    if (IsPlayerConnected(playerid) && s_UISession[playerid] == session &&
        s_CefBrowser[playerid] && !s_CefLoaded[playerid] && !s_CefClassic[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "CEF khong tai duoc. Da chuyen ve giao dien co ban.");
        UI_Classic(playerid);
    }
    return 1;
}

CMD:classicui(playerid, params[])
{
    #pragma unused params
    return UI_Classic(playerid);
}
