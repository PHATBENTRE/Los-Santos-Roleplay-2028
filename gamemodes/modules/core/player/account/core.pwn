#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Definitions
//-----------------------------------------------------------------------------

forward public OnPlayerAccountCheck(playerid);
forward public OnPasswordHash(playerid);
forward public OnPlayerRegister(playerid);
forward public OnPasswordCheck(playerid, bool:match);
forward public OnPlayerLogin(playerid);

#define MAX_LOGIN_ATTEMPTS (3)
static s_PlayerLoginAttempts[MAX_PLAYERS];

//-----------------------------------------------------------------------------
// Hooks
//-----------------------------------------------------------------------------

hook OnPlayerConnect(playerid)
{
    Account_Reset(playerid);
    Character_Reset(playerid);
    s_PlayerLoginAttempts[playerid] = 0;

    // Keep the player out of class selection/world until authentication and
    // character loading have completed.
    TogglePlayerSpectating(playerid, true);
    Account_ShowUsernameDialog(playerid);
    return 1;
}

hook OnPlayerAccountCheck(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 1;
    }


    // No master account exists yet: create one using the username already
    // stored by Account_Check.
    if (cache_num_rows() == 0)
    {
        Account_ShowRegistrationDialog(playerid);
        return 1;
    }

    new accountID;
    cache_get_value_name_int(0, "account_id", accountID);
    SetPlayerAccountID(playerid, accountID);

    new tempPassword[BCRYPT_HASH_LENGTH];
    cache_get_value_name(0, "password_hash", tempPassword);
    SetPVarString(playerid, "tempPassword", tempPassword);

    Account_ShowLoginDialog(playerid);
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (UI_UseCEF(playerid)) return 0;
    return Account_HandleResponse(playerid, dialogid, response, listitem, inputtext);
}

Account_HandleResponse(playerid, dialogid, response, listitem, const inputtext[])
{
    #pragma unused listitem

    if (IsPlayerLoggedIn(playerid) || s_UIStage[playerid] == UI_BUSY) return 0;
    if ((dialogid == DIALOG_ACCOUNT_USERNAME && s_UIStage[playerid] != UI_USERNAME) ||
        (dialogid == DIALOG_REGISTRATION && s_UIStage[playerid] != UI_REGISTER) ||
        (dialogid == DIALOG_LOGIN && s_UIStage[playerid] != UI_LOGIN)) return 0;

    switch (dialogid)
    {
        case DIALOG_ACCOUNT_USERNAME:
        {
            if (!response)
            {
                Kick(playerid);
                return 1;
            }

            if (!IsValidAccountUsername(inputtext))
            {
                Account_ShowUsernameDialog(playerid, true);
                return 1;
            }

            Account_Check(playerid, inputtext);
            s_UIStage[playerid] = UI_BUSY;
            return 1;
        }

        case DIALOG_REGISTRATION:
        {
            if (!response)
            {
                Account_ShowUsernameDialog(playerid);
                return 1;
            }

            if (!IsValidPassword(inputtext))
            {
                Account_ShowRegistrationDialog(playerid, true);
                return 1;
            }

            HashPassword(playerid, inputtext);
            s_UIStage[playerid] = UI_BUSY;
            return 1;
        }

        case DIALOG_LOGIN:
        {
            if (!response)
            {
                DeletePVar(playerid, "tempPassword");
                Account_ShowUsernameDialog(playerid);
                return 1;
            }

            new tempHash[BCRYPT_HASH_LENGTH];
            GetPVarString(playerid, "tempPassword", tempHash);
            bcrypt_verify(playerid, "OnPasswordCheck", inputtext, tempHash);
            s_UIStage[playerid] = UI_BUSY;
            return 1;
        }
    }

    return 0;
}

hook OnPasswordHash(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 1;
    }

    new hash[BCRYPT_HASH_LENGTH];
    bcrypt_get_hash(hash);
    Account_Create(playerid, hash);
    return 1;
}

hook OnPlayerRegister(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 1;
    }

    new const accountID = cache_insert_id();
    if (accountID == INVALID_ACCOUNT_ID)
    {
        SendClientMessage(playerid, COLOR_RED, "Tao tai khoan that bai. Hay ket noi lai va thu lai.");
        Kick(playerid);
        return 1;
    }

    SetPlayerAccountID(playerid, accountID);
    SetPlayerLoggedIn(playerid, true);
    s_PlayerLoginAttempts[playerid] = 0;

    CallLocalFunction("OnPlayerLogin", "d", playerid);
    return 1;
}

hook OnPasswordCheck(playerid, bool:match)
{
    if (!IsPlayerConnected(playerid))
    {
        return 1;
    }

    if (match)
    {
        if (IsAccountAlreadyOnline(playerid, GetPlayerAccountID(playerid)))
        {
            SendClientMessage(playerid, COLOR_RED, "Tai khoan LS:RP nay dang duoc dang nhap.");
            DeletePVar(playerid, "tempPassword");
            Kick(playerid);
            return 1;
        }

        SetPlayerLoggedIn(playerid, true);
        DeletePVar(playerid, "tempPassword");
        s_PlayerLoginAttempts[playerid] = 0;
        CallLocalFunction("OnPlayerLogin", "d", playerid);
        return 1;
    }

    s_PlayerLoginAttempts[playerid]++;

    if (s_PlayerLoginAttempts[playerid] >= MAX_LOGIN_ATTEMPTS)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban da bi ngat ket noi do nhap sai mat khau qua nhieu lan.");
        Kick(playerid);
        return 1;
    }

    Account_ShowLoginDialog(playerid);

    if (UI_UseCEF(playerid))
        UI_ReportError(playerid, 2, "Sai mat khau. Vui long thu lai.");

    new const attemptsLeft = MAX_LOGIN_ATTEMPTS - s_PlayerLoginAttempts[playerid];
    new message[96];
    format(message, sizeof(message), "Sai mat khau. Ban con %d lan thu.", attemptsLeft);
    SendClientMessage(playerid, COLOR_RED, message);
    return 1;
}

hook OnPlayerLogin(playerid)
{
    UI_Close(playerid);
    Character_LoadSlots(playerid);
    return 1;
}
