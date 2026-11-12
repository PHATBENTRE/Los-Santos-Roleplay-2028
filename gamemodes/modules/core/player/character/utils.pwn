//-----------------------------------------------------------------------------
// LS:RP Character System
//-----------------------------------------------------------------------------

#define MAX_CHARACTER_SLOTS          (3)
#define INVALID_CHARACTER_ID         (0)
#define CHARACTER_NAME_LENGTH        (25)

#define DEFAULT_CHARACTER_SKIN       (26)
#define DEFAULT_CHARACTER_CASH       (500)
#define DEFAULT_CHARACTER_BANK       (0)
#define DEFAULT_CHARACTER_LEVEL      (1)

#define GAME_CONTEXT_YEAR            (1992)
#define CHARACTER_MIN_AGE            (18)
#define CHARACTER_MAX_AGE            (80)

#define CHARACTER_MIN_BIRTH_YEAR     (1912)
#define CHARACTER_MAX_BIRTH_YEAR     (1974)
// Ganton
#define GANTON_SPAWN_X               (2495.3633)
#define GANTON_SPAWN_Y               (-1687.3105)
#define GANTON_SPAWN_Z               (13.5156)
#define GANTON_SPAWN_A               (0.0)

//-----------------------------------------------------------------------------
// Character runtime data
//
// DUNG new thay vi static vi cac bien nay duoc su dung qua nhieu module.
//-----------------------------------------------------------------------------

new
    s_CharacterID[MAX_PLAYERS],
    s_CharacterSlot[MAX_PLAYERS],
    s_CharacterName[MAX_PLAYERS][CHARACTER_NAME_LENGTH],

    s_CharacterSkin[MAX_PLAYERS],
    s_CharacterCash[MAX_PLAYERS],
    s_CharacterBank[MAX_PLAYERS],
    s_CharacterLevel[MAX_PLAYERS],

    Float:s_CharacterHealth[MAX_PLAYERS],
    Float:s_CharacterArmour[MAX_PLAYERS],

    Float:s_CharacterPosX[MAX_PLAYERS],
    Float:s_CharacterPosY[MAX_PLAYERS],
    Float:s_CharacterPosZ[MAX_PLAYERS],
    Float:s_CharacterPosA[MAX_PLAYERS],

    s_CharacterInterior[MAX_PLAYERS],
    s_CharacterVirtualWorld[MAX_PLAYERS],

    bool:s_CharacterLoaded[MAX_PLAYERS],

    // Ho so nhan vat
    s_CharacterCreated[MAX_PLAYERS],
    s_CharacterGender[MAX_PLAYERS],
    s_CharacterBirthDay[MAX_PLAYERS],
    s_CharacterBirthMonth[MAX_PLAYERS],
    s_CharacterBirthYear[MAX_PLAYERS],
    s_CharacterSkinTone[MAX_PLAYERS],
    s_CharacterVoice[MAX_PLAYERS],
    s_CharacterHeight[MAX_PLAYERS],
    s_CharacterWeight[MAX_PLAYERS],
    s_CharacterBirthPlace[MAX_PLAYERS],

    // 3 slots
    s_CharacterSlotID[MAX_PLAYERS][MAX_CHARACTER_SLOTS],
    s_CharacterSlotName[MAX_PLAYERS][MAX_CHARACTER_SLOTS][CHARACTER_NAME_LENGTH],
    s_CharacterSlotLevel[MAX_PLAYERS][MAX_CHARACTER_SLOTS],
    s_CharacterSlotSkin[MAX_PLAYERS][MAX_CHARACTER_SLOTS],
    

    s_SelectedCharacterSlot[MAX_PLAYERS],
    s_PendingCharacterName[MAX_PLAYERS][CHARACTER_NAME_LENGTH];

//-----------------------------------------------------------------------------
// Reset
//-----------------------------------------------------------------------------

Character_ClearSlots(playerid)
{
    for (new slot = 0; slot < MAX_CHARACTER_SLOTS; slot++)
    {
        s_CharacterSlotID[playerid][slot] = INVALID_CHARACTER_ID;
        s_CharacterSlotName[playerid][slot][0] = 0;
        s_CharacterSlotLevel[playerid][slot] = 0;
        s_CharacterSlotSkin[playerid][slot] = 0;
    }
    return 1;
}

Character_Reset(playerid)
{
    s_CharacterID[playerid] = INVALID_CHARACTER_ID;
    s_CharacterSlot[playerid] = 0;

    s_CharacterName[playerid][0] = 0;

    s_CharacterSkin[playerid] = DEFAULT_CHARACTER_SKIN;
    s_CharacterCash[playerid] = DEFAULT_CHARACTER_CASH;
    s_CharacterBank[playerid] = DEFAULT_CHARACTER_BANK;
    s_CharacterLevel[playerid] = DEFAULT_CHARACTER_LEVEL;

    s_CharacterHealth[playerid] = 100.0;
    s_CharacterArmour[playerid] = 0.0;

    s_CharacterPosX[playerid] = GANTON_SPAWN_X;
    s_CharacterPosY[playerid] = GANTON_SPAWN_Y;
    s_CharacterPosZ[playerid] = GANTON_SPAWN_Z;
    s_CharacterPosA[playerid] = GANTON_SPAWN_A;

    s_CharacterInterior[playerid] = 0;
    s_CharacterVirtualWorld[playerid] = 0;

    s_CharacterLoaded[playerid] = false;

    // Profile defaults
    s_CharacterCreated[playerid] = 0;
    s_CharacterGender[playerid] = 0;

    s_CharacterBirthDay[playerid] = 1;
    s_CharacterBirthMonth[playerid] = 1;
    s_CharacterBirthYear[playerid] = 2000;

    s_CharacterSkinTone[playerid] = 2;
    s_CharacterVoice[playerid] = 0;

    s_CharacterHeight[playerid] = 175;
    s_CharacterWeight[playerid] = 70;
    s_CharacterBirthPlace[playerid] = 0;

    s_SelectedCharacterSlot[playerid] = 0;
    s_PendingCharacterName[playerid][0] = 0;

    Character_ClearSlots(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Getters
//-----------------------------------------------------------------------------

stock bool:IsPlayerCharacterLoaded(playerid)
{
    return s_CharacterLoaded[playerid];
}

stock GetPlayerCharacterID(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return INVALID_CHARACTER_ID;
    }

    return s_CharacterID[playerid];
}

stock GetPlayerCharacterAge(playerid)
{
    return GAME_CONTEXT_YEAR - s_CharacterBirthYear[playerid];
}

//-----------------------------------------------------------------------------
// Character name
//-----------------------------------------------------------------------------

bool:Character_SetPlayerICName(playerid)
{
    new currentName[25];
    GetPlayerName(playerid, currentName, sizeof(currentName));

    if (!strcmp(currentName, s_CharacterName[playerid], false))
    {
        return true;
    }

    if (SetPlayerName(playerid, s_CharacterName[playerid]) != 1)
    {
        SendClientMessage(
            playerid,
            COLOR_RED,
            "Khong the su dung ten nhan vat nay luc nay."
        );

        return false;
    }

    return true;
}

//-----------------------------------------------------------------------------
// Slots
//-----------------------------------------------------------------------------

Character_LoadSlots(playerid)
{
    if (!IsPlayerLoggedIn(playerid))
    {
        return 0;
    }

    Character_ClearSlots(playerid);

    new query[256];

    mysql_format(g_DatabaseHandle, query, sizeof(query),
    "SELECT `character_id`,`slot`,`name`,`level`,`skin` FROM `player_characters` WHERE `account_id`=%d ORDER BY `slot` ASC;",
    GetPlayerAccountID(playerid)
    );

    mysql_tquery(
        g_DatabaseHandle,
        query,
        "OnCharacterSlotsLoaded",
        "d",
        playerid
    );


    return 1;
}

Character_FormatSlot(playerid, slotIndex, destination[], size)
{
    if (s_CharacterSlotID[playerid][slotIndex] == INVALID_CHARACTER_ID)
    {
        format(
            destination,
            size,
            "Slot %d: [Trong - Tao nhan vat]",
            slotIndex + 1
        );
    }
    else
    {
        format(
            destination,
            size,
            "Slot %d: %s (Cap do %d)",
            slotIndex + 1,
            s_CharacterSlotName[playerid][slotIndex],
            s_CharacterSlotLevel[playerid][slotIndex]
        );
    }

    return 1;
}

Character_ShowSelectionDialog(playerid)
{
    new
        slot1[80],
        slot2[80],
        slot3[80],
        body[280];

    Character_FormatSlot(playerid, 0, slot1, sizeof(slot1));
    Character_FormatSlot(playerid, 1, slot2, sizeof(slot2));
    Character_FormatSlot(playerid, 2, slot3, sizeof(slot3));

    format(
        body,
        sizeof(body),
        "%s\n%s\n%s",
        slot1,
        slot2,
        slot3
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_CHARACTER_SELECT,
        DIALOG_STYLE_LIST,
        "LS:RP - Chon nhan vat",
        body,
        "Chon",
        "Thoat"
    );

    return 1;
}

//-----------------------------------------------------------------------------
// Character name creation
//-----------------------------------------------------------------------------

Character_ShowNameDialog(
    playerid,
    bool:invalid = false,
    bool:taken = false
)
{
    if (UI_UseCEF(playerid))
    {
        UI_Show(playerid, UI_CREATOR);
        if (invalid || taken) UI_CreatorFail(playerid, taken ? 4 : 5);
        return 1;
    }
    ShowPlayerDialog(
        playerid,
        DIALOG_CHARACTER_NAME,
        DIALOG_STYLE_INPUT,
        "LS:RP - Tao nhan vat",
        "Nhap ten nhan vat theo dinh dang First_Last.\nVi du: Michael_Johnson",
        "Tiep tuc",
        "Quay lai"
    );

    if (invalid)
    {
        SendClientMessage(
            playerid,
            COLOR_RED,
            "Ten khong hop le. Vi du hop le: Michael_Johnson."
        );
    }
    else if (taken)
    {
        SendClientMessage(
            playerid,
            COLOR_RED,
            "Ten nhan vat nay da duoc su dung."
        );
    }

    return 1;
}

bool:IsValidCharacterName(const name[])
{
    new const length = strlen(name);

    if (length < 5 || length > 24)
    {
        return false;
    }

    new underscore = -1;

    for (new i = 0; i < length; i++)
    {
        new const ch = name[i];

        if (ch == '_')
        {
            if (underscore != -1)
            {
                return false;
            }

            underscore = i;
            continue;
        }

        if (!(
            (ch >= 'A' && ch <= 'Z') ||
            (ch >= 'a' && ch <= 'z')
        ))
        {
            return false;
        }
    }

    return underscore >= 2 && underscore <= (length - 3);
}

Character_CheckName(playerid, const name[])
{
    format(
        s_PendingCharacterName[playerid],
        CHARACTER_NAME_LENGTH,
        "%s",
        name
    );

    new query[256];

    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "SELECT `character_id` FROM `player_characters` WHERE `name`='%e' LIMIT 1;",
        name
    );

    mysql_tquery(
        g_DatabaseHandle,
        query,
        "OnCharacterNameCheck",
        "d",
        playerid
    );

    UI_Notify(playerid, "info", "Đang kiểm tra tên nhân vật với máy chủ...");

    return 1;
}

//-----------------------------------------------------------------------------
// Character creation
//-----------------------------------------------------------------------------

Character_Create(playerid)
{
    new const slot = s_SelectedCharacterSlot[playerid];

    if (slot < 1 || slot > MAX_CHARACTER_SLOTS)
    {
        Character_LoadSlots(playerid);
        return 0;
    }

    new query[768];

    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "INSERT INTO `player_characters` (`account_id`,`slot`,`name`,`skin`,`cash`,`bank`,`level`,`health`,`armour`,`pos_x`,`pos_y`,`pos_z`,`pos_a`,`interior_id`,`virtual_world`,`character_created`) VALUES (%d,%d,'%e',%d,%d,%d,%d,100.0,0.0,%f,%f,%f,%f,0,0,0);",
        GetPlayerAccountID(playerid),
        slot,
        s_PendingCharacterName[playerid],
        DEFAULT_CHARACTER_SKIN,
        DEFAULT_CHARACTER_CASH,
        DEFAULT_CHARACTER_BANK,
        DEFAULT_CHARACTER_LEVEL,
        GANTON_SPAWN_X,
        GANTON_SPAWN_Y,
        GANTON_SPAWN_Z,
        GANTON_SPAWN_A
    );

    mysql_tquery(
        g_DatabaseHandle,
        query,
        "OnCharacterCreated",
        "d",
        playerid
    );

    return 1;
}

//-----------------------------------------------------------------------------
// Character load
//-----------------------------------------------------------------------------

Character_LoadByID(playerid, characterID)
{
    new query[1024];

    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "SELECT `character_id`,`slot`,`name`,`character_created`,`gender`,`birth_day`,`birth_month`,`birth_year`,`skin_tone`,`voice`,`height_cm`,`weight_kg`,`birth_place`,`skin`,`cash`,`bank`,`level`,`health`,`armour`,`pos_x`,`pos_y`,`pos_z`,`pos_a`,`interior_id`,`virtual_world` FROM `player_characters` WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;",
        characterID,
        GetPlayerAccountID(playerid)
    );

    mysql_tquery(
        g_DatabaseHandle,
        query,
        "Character_LoadResult",
        "dd",
        playerid,
        s_UISession[playerid]
    );

    return 1;
}

//-----------------------------------------------------------------------------
// Save
//-----------------------------------------------------------------------------

Character_Save(playerid)
{
    if (!s_CharacterLoaded[playerid])
    {
        return 0;
    }

    // Character chua hoan tat Character Creator thi khong save vi tri can nha.
    if (!s_CharacterCreated[playerid])
    {
        return 0;
    }

    new
        Float:x,
        Float:y,
        Float:z,
        Float:a,
        Float:health,
        Float:armour;

    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    GetPlayerHealth(playerid, health);
    GetPlayerArmour(playerid, armour);

    s_CharacterSkin[playerid] = GetPlayerSkin(playerid);
    s_CharacterCash[playerid] = GetPlayerMoney(playerid);
    s_CharacterLevel[playerid] = GetPlayerScore(playerid);

    s_CharacterHealth[playerid] = health;
    s_CharacterArmour[playerid] = armour;

    s_CharacterPosX[playerid] = x;
    s_CharacterPosY[playerid] = y;
    s_CharacterPosZ[playerid] = z;
    s_CharacterPosA[playerid] = a;

    s_CharacterInterior[playerid] = GetPlayerInterior(playerid);
    s_CharacterVirtualWorld[playerid] = GetPlayerVirtualWorld(playerid);

    new query[1024];

    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_characters` SET `skin`=%d,`cash`=%d,`bank`=%d,`level`=%d,`health`=%f,`armour`=%f,`pos_x`=%f,`pos_y`=%f,`pos_z`=%f,`pos_a`=%f,`interior_id`=%d,`virtual_world`=%d,`last_played`=CURRENT_TIMESTAMP WHERE `character_id`=%d AND `account_id`=%d;",
        s_CharacterSkin[playerid],
        s_CharacterCash[playerid],
        s_CharacterBank[playerid],
        s_CharacterLevel[playerid],
        s_CharacterHealth[playerid],
        s_CharacterArmour[playerid],
        s_CharacterPosX[playerid],
        s_CharacterPosY[playerid],
        s_CharacterPosZ[playerid],
        s_CharacterPosA[playerid],
        s_CharacterInterior[playerid],
        s_CharacterVirtualWorld[playerid],
        s_CharacterID[playerid],
        GetPlayerAccountID(playerid)
    );

    mysql_tquery(g_DatabaseHandle, query);
    return 1;
}

//-----------------------------------------------------------------------------
// Spawn
//-----------------------------------------------------------------------------

Character_ApplySpawn(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    if (!Character_SetPlayerICName(playerid))
    {
        Kick(playerid);
        return 0;
    }

    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);

    SetSpawnInfo(
        playerid,
        NO_TEAM,
        s_CharacterSkin[playerid],
        GANTON_SPAWN_X,
        GANTON_SPAWN_Y,
        GANTON_SPAWN_Z,
        GANTON_SPAWN_A
    );

    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        TogglePlayerSpectating(playerid, false);
    }
    else
    {
        SpawnPlayer(playerid);
    }

    return 1;
}
