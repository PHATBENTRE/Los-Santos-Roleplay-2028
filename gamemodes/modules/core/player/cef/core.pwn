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
    CEF_RegisterEvent("lsrp:creator_confirm", "LSRP_CreatorConfirm", Argument_String);
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
    if (!strcmp(url, s_UILastURL[playerid])) return 1;
    format(s_UILastURL[playerid], 768, "%s", url);
    printf("[GTASA UI] state sent via navigation player=%d stage=%d rev=%d", playerid, s_UIStage[playerid], s_UIRevision[playerid]);
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
    if (!s_CefLoaded[playerid]) printf("[GTASA UI] page ready player=%d browser=%d stage=%d", playerid, browserid, s_UIStage[playerid]);
    s_CefLoaded[playerid] = true;
    CEF_SetBrowserVisible(playerid, LSRP_BROWSER, true);
    CEF_FocusBrowser(playerid, LSRP_BROWSER, true);
    return LSRP_UIRender(playerid);
}

forward LSRP_UISubmit(playerid, browserid, const value[]);
public LSRP_UISubmit(playerid, browserid, const value[])
{
    // Log transport/state only. Never log submitted credentials.
    printf("[GTASA UI] submit player=%d browser=%d stage=%d ready=%d", playerid, browserid, s_UIStage[playerid], s_CefLoaded[playerid]);
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

forward LSRP_CreatorConfirm(playerid, browserid, const name[]);
public LSRP_CreatorConfirm(playerid, browserid, const name[])
{
    printf("[GTASA UI] creator confirm player=%d browser=%d stage=%d active=%d", playerid, browserid, s_UIStage[playerid], CharacterCreator_IsActive(playerid));
    if (browserid != LSRP_BROWSER || !UI_Action(playerid) || s_UIStage[playerid] != UI_CREATOR)
    {
        UI_ReportError(playerid, 0, "Trình tạo nhân vật chưa sẵn sàng. Hãy mở lại creator.");
        return 0;
    }
    if (!CharacterCreator_IsActive(playerid))
    {
        if (!IsValidCharacterName(name)) { UI_Notify(playerid, "warning", "Tên nhân vật phải có dạng First_Last."); return 0; }
        printf("[GTASA UI] creator name check begin player=%d name=%s", playerid, name);
        Character_CheckName(playerid, name);
        UI_Notify(playerid, "info", "Đang kiểm tra tên nhân vật...");
        return 1;
    }
    return CharacterCreator_Confirm(playerid);
}

forward LSRP_UIClassic(playerid, browserid);
public LSRP_UIClassic(playerid, browserid)
{
    if (browserid != LSRP_BROWSER || !IsPlayerConnected(playerid)) return 0;
    return UI_Classic(playerid);
}

UI_Classic(playerid)
{
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
    }
    return 1;
}

public OnCefReady(playerid)
{
    printf("[GTASA UI] resources ready player=%d stage=%d", playerid, s_UIStage[playerid]);
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
