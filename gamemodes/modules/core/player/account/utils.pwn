//-----------------------------------------------------------------------------
// Definitions
//-----------------------------------------------------------------------------

// Account username and password limits.
#define ACCOUNT_MIN_USERNAME_LENGTH (3)
#define ACCOUNT_MAX_USERNAME_LENGTH (24)
#define ACCOUNT_USERNAME_LENGTH     (ACCOUNT_MAX_USERNAME_LENGTH + 1)
#define ACCOUNT_MIN_PASSWORD_LENGTH (6)

// Invalid database account ID.
#define INVALID_ACCOUNT_ID          (0)

// Player account data variables.
static
        s_PlayerAccountID[MAX_PLAYERS],
        s_PlayerAccountUsername[MAX_PLAYERS][ACCOUNT_USERNAME_LENGTH],
        bool:s_IsPlayerLoggedIn[MAX_PLAYERS];

//-----------------------------------------------------------------------------
// Functions
//-----------------------------------------------------------------------------

Account_Reset(playerid)
{
    s_PlayerAccountID[playerid] = INVALID_ACCOUNT_ID;
    s_PlayerAccountUsername[playerid][0] = 0;
    s_IsPlayerLoggedIn[playerid] = false;

    DeletePVar(playerid, "tempPassword");
    return 1;
}

// Shows the account username prompt.  The launcher nickname is intentionally
// kept separate from the master account username.
Account_ShowUsernameDialog(playerid, bool:invalid = false)
{
    if (UI_Show(playerid, UI_USERNAME)) return 1;
    ShowPlayerDialog(
        playerid,
        DIALOG_ACCOUNT_USERNAME,
        DIALOG_STYLE_INPUT,
        "GTASA Vietnamese - Dang nhap",
        "Nhap ten dang nhap cua ban.\n\nTen dang nhap duoc dung chung cho cac nhan vat.",
        "Tiep tuc",
        "Thoat"
    );

    if (invalid)
    {
        SendClientMessage(playerid, COLOR_RED, "Ten tai khoan phai co 3-24 ky tu, chi gom chu cai, chu so hoac dau gach duoi.");
    }
    return 1;
}

bool:IsValidAccountUsername(const username[])
{
    new const length = strlen(username);
    if (length < ACCOUNT_MIN_USERNAME_LENGTH || length > ACCOUNT_MAX_USERNAME_LENGTH)
    {
        return false;
    }

    for (new i = 0; i < length; i++)
    {
        new const ch = username[i];
        if (!((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '_'))
        {
            return false;
        }
    }
    return true;
}

SetPlayerAccountUsername(playerid, const username[])
{
    format(s_PlayerAccountUsername[playerid], ACCOUNT_USERNAME_LENGTH, "%s", username);
    return 1;
}

stock GetPlayerAccountUsername(playerid, destination[], size)
{
    format(destination, size, "%s", s_PlayerAccountUsername[playerid]);
    return 1;
}

// Checks whether the entered master account username already exists.
Account_Check(playerid, const username[])
{
    SetPlayerAccountUsername(playerid, username);
    s_PlayerAccountID[playerid] = INVALID_ACCOUNT_ID;
    SetPlayerLoggedIn(playerid, false);

    new query[256];
    mysql_format(g_DatabaseHandle, query, sizeof(query), "SELECT `account_id`,`password_hash` FROM `player_accounts` WHERE `username`='%e' LIMIT 1;", username);
    mysql_tquery(g_DatabaseHandle, query, "OnPlayerAccountCheck", "d", playerid);
    return 1;
}

// Shows the registration dialog to the player.
Account_ShowRegistrationDialog(playerid, bool:badpass = false)
{
    if (UI_Show(playerid, UI_REGISTER)) return 1;
    ShowPlayerDialog(
        playerid,
        DIALOG_REGISTRATION,
        DIALOG_STYLE_PASSWORD,
        "LS:RP - Dang ky tai khoan",
        "Tao mat khau cho tai khoan.\n\nMat khau phai co it nhat %d ky tu:",
        "Dang ky",
        "Quay lai",
        ACCOUNT_MIN_PASSWORD_LENGTH
    );

    if (badpass)
    {
        SendClientMessage(playerid, COLOR_RED, "Mat khau qua ngan. Hay chon mat khau manh hon.");
    }
    return 1;
}

// Shows the login dialog to the player.
Account_ShowLoginDialog(playerid)
{
    if (UI_Show(playerid, UI_LOGIN)) return 1;
    new username[ACCOUNT_USERNAME_LENGTH], caption[64];
    GetPlayerAccountUsername(playerid, username, sizeof(username));
    format(caption, sizeof(caption), "Dang nhap - %s", username);

    ShowPlayerDialog(
        playerid,
        DIALOG_LOGIN,
        DIALOG_STYLE_PASSWORD,
        caption,
        "Nhap mat khau cua tai khoan LS:RP.",
        "Dang nhap",
        "Quay lai"
    );
    return 1;
}

bool:IsValidPassword(const password[])
{
    return strlen(password) >= ACCOUNT_MIN_PASSWORD_LENGTH;
}

HashPassword(playerid, const password[])
{
    bcrypt_hash(playerid, "OnPasswordHash", password, BCRYPT_COST);
    return 1;
}

// Creates only the master account.  IC character data belongs in
// `player_characters`, never in this table.
Account_Create(playerid, const hash[])
{
    new query[384], username[ACCOUNT_USERNAME_LENGTH];
    GetPlayerAccountUsername(playerid, username, sizeof(username));

    mysql_format(g_DatabaseHandle, query, sizeof(query), "INSERT INTO `player_accounts` (`username`,`password_hash`) VALUES ('%e','%e');", username, hash);
    mysql_tquery(g_DatabaseHandle, query, "OnPlayerRegister", "d", playerid);
    return 1;
}

SetPlayerAccountID(playerid, accountid)
{
    s_PlayerAccountID[playerid] = accountid;
    return 1;
}

stock GetPlayerAccountID(playerid)
{
    return s_PlayerAccountID[playerid];
}

SetPlayerLoggedIn(playerid, bool:set)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    s_IsPlayerLoggedIn[playerid] = set;
    return 1;
}

stock bool:IsPlayerLoggedIn(playerid)
{
    return IsPlayerConnected(playerid) && s_IsPlayerLoggedIn[playerid];
}

bool:IsAccountAlreadyOnline(playerid, accountid)
{
    if (accountid == INVALID_ACCOUNT_ID)
    {
        return false;
    }

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (i == playerid || !IsPlayerConnected(i) || !IsPlayerLoggedIn(i))
        {
            continue;
        }

        if (GetPlayerAccountID(i) == accountid)
        {
            return true;
        }
    }
    return false;
}
