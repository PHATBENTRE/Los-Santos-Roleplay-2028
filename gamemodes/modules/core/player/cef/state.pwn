#include <YSI_Coding\y_hooks>

#define LSRP_BROWSER (2028)
#define UI_USERNAME (1)
#define UI_REGISTER (2)
#define UI_LOGIN (3)
#define UI_SLOTS (4)
#define UI_BUSY (5)
#define UI_CREATOR (6)
new s_UIStage[MAX_PLAYERS];
new bool:s_CefReady[MAX_PLAYERS], bool:s_CefBrowser[MAX_PLAYERS], bool:s_CefLoaded[MAX_PLAYERS], bool:s_CefClassic[MAX_PLAYERS];
new s_CefLastAction[MAX_PLAYERS];
new s_UISession[MAX_PLAYERS];
new s_UIRevision[MAX_PLAYERS];
new s_UIError[MAX_PLAYERS];
new s_UILastURL[MAX_PLAYERS][768];
new s_UIToastRevision[MAX_PLAYERS], s_UIToastUntil[MAX_PLAYERS];
new s_UIHideRequest[MAX_PLAYERS];
// A creator submission is a single server-owned operation, independent of toast delivery.
enum E_UI_CREATOR_PROFILE
{
    cpGender, cpDay, cpMonth, cpYear, cpTone, cpVoice, cpHeight, cpWeight, cpBirthplace
};
new s_UICreatorProfile[MAX_PLAYERS][E_UI_CREATOR_PROFILE];
new bool:s_UICreatorPending[MAX_PLAYERS];
new s_UICreatorRequest[MAX_PLAYERS];
new s_UICreatorName[MAX_PLAYERS][25];
new s_UICreatorSlot[MAX_PLAYERS];

hook OnPlayerConnect(playerid)
{
    s_UIStage[playerid] = 0;
    s_UIRevision[playerid] = 0;
    s_UIError[playerid] = 0;
    s_UIToastRevision[playerid] = 0;
    s_UIToastUntil[playerid] = 0;
    s_UIHideRequest[playerid]++;
    s_UICreatorPending[playerid] = false;
    s_UICreatorRequest[playerid]++;
    s_UICreatorName[playerid][0] = EOS;
    s_UILastURL[playerid][0] = EOS;
    s_UISession[playerid]++;
    s_CefReady[playerid] = false;
    s_CefBrowser[playerid] = false;
    s_CefLoaded[playerid] = false;
    s_CefClassic[playerid] = false;
    s_CefLastAction[playerid] = GetTickCount() - 1000;
    return 1;
}

stock bool:UI_UseCEF(playerid)
{
    return s_CefReady[playerid] && !s_CefClassic[playerid];
}

stock UI_Notify(playerid, const type[], const message[])
{
    if (!UI_UseCEF(playerid) || !s_CefLoaded[playerid]) return 0;
    if (!strcmp(type, "success") && !strcmp(message, "Đã tạo nhân vật thành công."))
    {
        s_UIToastRevision[playerid]++;
        s_UIToastUntil[playerid] = GetTickCount() + 4500;
    }
    else CEF_EmitEvent(playerid, LSRP_BROWSER, "lsrp:notify", CEF_STR(type), CEF_STR(message));
    return 1;
}

forward LSRP_UIHideAfterToast(playerid, session, hideRequest);
public LSRP_UIHideAfterToast(playerid, session, hideRequest)
{
    if (!IsPlayerConnected(playerid) || s_UISession[playerid] != session ||
        s_UIStage[playerid] != 0 || s_UIHideRequest[playerid] != hideRequest) return 1;
    if (s_CefBrowser[playerid]) CEF_SetBrowserVisible(playerid, LSRP_BROWSER, false);
    return 1;
}

stock UI_Close(playerid)
{
    if (s_UIStage[playerid] == 0) return 1;
    s_UIHideRequest[playerid]++;
    s_UIStage[playerid] = 0;
    s_UIRevision[playerid]++;
    if (s_CefLoaded[playerid]) CallLocalFunction("LSRP_UIRender", "d", playerid);
    if (s_CefBrowser[playerid])
    {
        CEF_FocusBrowser(playerid, LSRP_BROWSER, false);
        new remaining = s_UIToastUntil[playerid] - GetTickCount();
        if (remaining > 0 && remaining <= 4500)
        {
            CEF_SetBrowserVisible(playerid, LSRP_BROWSER, true);
            // The browser stays transparent until JS drains its notification queue.
            // This is only a fallback if the browser never sends the drained event.
            SetTimerEx("LSRP_UIHideAfterToast", 300000, false, "ddd", playerid,
                s_UISession[playerid], s_UIHideRequest[playerid]);
        }
        else CEF_SetBrowserVisible(playerid, LSRP_BROWSER, false);
        CEF_ToggleChatInput(playerid, true);
    }
    return 1;
}

stock UI_Show(playerid, stage)
{
    s_UIHideRequest[playerid]++;
    s_UIStage[playerid] = stage;
    s_UIError[playerid] = 0;
    s_UIRevision[playerid]++;
    if (!UI_UseCEF(playerid)) return 0;
    HidePlayerDialog(playerid);
    if (!s_CefBrowser[playerid])
    {
        s_CefBrowser[playerid] = true;
        CEF_CreateBrowser(playerid, LSRP_BROWSER, "http://cef/lsrp/index.html?v=4", false);
        SetTimerEx("LSRP_UILoadTimeout", 15000, false, "dd", playerid, s_UISession[playerid]);
    }
    else
    {
        CEF_SetBrowserVisible(playerid, LSRP_BROWSER, true);
        CEF_FocusBrowser(playerid, LSRP_BROWSER, true);
    }
    CEF_ToggleChatInput(playerid, false);
    if (s_CefLoaded[playerid]) CallLocalFunction("LSRP_UIRender", "d", playerid);
    return 1;
}
