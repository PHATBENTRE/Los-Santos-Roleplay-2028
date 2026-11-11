#include <YSI_Coding\y_hooks>

#define LSRP_BROWSER (2028)
#define UI_USERNAME (1)
#define UI_REGISTER (2)
#define UI_LOGIN (3)
#define UI_SLOTS (4)
#define UI_BUSY (5)
new s_UIStage[MAX_PLAYERS];
new bool:s_CefReady[MAX_PLAYERS], bool:s_CefBrowser[MAX_PLAYERS], bool:s_CefLoaded[MAX_PLAYERS], bool:s_CefClassic[MAX_PLAYERS];
new s_CefLastAction[MAX_PLAYERS];
new s_UISession[MAX_PLAYERS];
new s_UIRevision[MAX_PLAYERS];
new s_UIError[MAX_PLAYERS];
new s_UILastURL[MAX_PLAYERS][768];

hook OnPlayerConnect(playerid)
{
    s_UIStage[playerid] = 0;
    s_UIRevision[playerid] = 0;
    s_UIError[playerid] = 0;
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

stock UI_Close(playerid)
{
    if (s_CefBrowser[playerid])
    {
        CEF_FocusBrowser(playerid, LSRP_BROWSER, false);
        CEF_SetBrowserVisible(playerid, LSRP_BROWSER, false);
        CEF_ToggleChatInput(playerid, true);
    }
    s_UIStage[playerid] = 0;
    return 1;
}

stock UI_Show(playerid, stage)
{
    s_UIStage[playerid] = stage;
    s_UIError[playerid] = 0;
    s_UIRevision[playerid]++;
    if (!UI_UseCEF(playerid)) return 0;
    HidePlayerDialog(playerid);
    if (!s_CefBrowser[playerid])
    {
        s_CefBrowser[playerid] = true;
        CEF_CreateBrowser(playerid, LSRP_BROWSER, "http://cef/lsrp/index.html?v=3", false);
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
