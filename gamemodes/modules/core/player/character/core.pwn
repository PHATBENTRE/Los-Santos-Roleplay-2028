#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Callbacks
//-----------------------------------------------------------------------------

forward public OnCharacterSlotsLoaded(playerid);
forward public OnCharacterNameCheck(playerid);
forward public OnCharacterCreated(playerid);
forward public OnCharacterLoaded(playerid);
forward Character_LoadResult(playerid, session);

//-----------------------------------------------------------------------------
// Slots loaded
//-----------------------------------------------------------------------------

public OnCharacterSlotsLoaded(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerLoggedIn(playerid))
    {
        return 1;
    }

    Character_ClearSlots(playerid);

    new const rows = cache_num_rows();

    for (new row = 0; row < rows; row++)
    {
        new
            slot,
            characterID,
            level;

        cache_get_value_name_int(
            row,
            "slot",
            slot
        );
        new skin;
        cache_get_value_name_int(row, "skin", skin);

        cache_get_value_name_int(
            row,
            "character_id",
            characterID
        );

        cache_get_value_name_int(
            row,
            "level",
            level
        );

        if (slot < 1 ||
            slot > MAX_CHARACTER_SLOTS)
        {
            continue;
        }

        new const index = slot - 1;

        s_CharacterSlotID[playerid][index] =
            characterID;

        s_CharacterSlotLevel[playerid][index] =
            level;
        
        s_CharacterSlotSkin[playerid][index] = skin;

        cache_get_value_name(
            row,
            "name",
            s_CharacterSlotName[playerid][index],
            CHARACTER_NAME_LENGTH
        );
    }

    // Character_ShowSelectionDialog(playerid);
    Cinematic_StartSelector(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Name check
//-----------------------------------------------------------------------------

public OnCharacterNameCheck(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerLoggedIn(playerid))
    {
        return 1;
    }

    if (cache_num_rows() > 0)
    {
        UI_Notify(playerid, "warning", "Tên nhân vật đã được sử dụng.");
        Character_ShowNameDialog(
            playerid,
            false,
            true
        );

        return 1;
    }

    Character_Create(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Character created
//-----------------------------------------------------------------------------

public OnCharacterCreated(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerLoggedIn(playerid))
    {
        return 1;
    }

    new const characterID = cache_insert_id();

    if (characterID == INVALID_CHARACTER_ID)
    {
        UI_Notify(playerid, "error", "Không thể tạo nhân vật. Hãy thử lại.");
        SendClientMessage(
            playerid,
            COLOR_RED,
            "Khong the tao nhan vat. Hay thu lai."
        );

        Character_LoadSlots(playerid);
        return 1;
    }

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        "Ten nhan vat da duoc tao. Dang khoi tao ho so..."
    );
    UI_Notify(playerid, "success", "Tên nhân vật đã được tạo. Đang khởi tạo hồ sơ...");

    Character_LoadByID(
        playerid,
        characterID
    );

    return 1;
}

//-----------------------------------------------------------------------------
// Character load
//-----------------------------------------------------------------------------

public Character_LoadResult(playerid, session)
{
    if (!IsPlayerConnected(playerid) || s_UISession[playerid] != session) return 0;
    // Keep the public callback ABI used by the vehicle/job hooks unchanged.
    return CallLocalFunction("OnCharacterLoaded", "d", playerid);
}

public OnCharacterLoaded(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerLoggedIn(playerid))
    {
        return 1;
    }

    if (cache_num_rows() == 0)
    {
        if (s_UICreatorPending[playerid]) return UI_CreatorFail(playerid, 8);
        SendClientMessage(
            playerid,
            COLOR_RED,
            "Khong the tai du lieu nhan vat."
        );

        Character_LoadSlots(playerid);
        return 1;
    }

    cache_get_value_name_int(
        0,
        "character_id",
        s_CharacterID[playerid]
    );

    cache_get_value_name_int(
        0,
        "slot",
        s_CharacterSlot[playerid]
    );

    cache_get_value_name(
        0,
        "name",
        s_CharacterName[playerid],
        CHARACTER_NAME_LENGTH
    );

    cache_get_value_name_int(
        0,
        "character_created",
        s_CharacterCreated[playerid]
    );

    cache_get_value_name_int(
        0,
        "gender",
        s_CharacterGender[playerid]
    );

    cache_get_value_name_int(
        0,
        "birth_day",
        s_CharacterBirthDay[playerid]
    );

    cache_get_value_name_int(
        0,
        "birth_month",
        s_CharacterBirthMonth[playerid]
    );

    cache_get_value_name_int(
        0,
        "birth_year",
        s_CharacterBirthYear[playerid]
    );

    cache_get_value_name_int(
        0,
        "skin_tone",
        s_CharacterSkinTone[playerid]
    );

    cache_get_value_name_int(
        0,
        "voice",
        s_CharacterVoice[playerid]
    );

    cache_get_value_name_int(
        0,
        "height_cm",
        s_CharacterHeight[playerid]
    );

    cache_get_value_name_int(
        0,
        "weight_kg",
        s_CharacterWeight[playerid]
    );

    cache_get_value_name_int(
        0,
        "birth_place",
        s_CharacterBirthPlace[playerid]
    );

    cache_get_value_name_int(
        0,
        "skin",
        s_CharacterSkin[playerid]
    );

    cache_get_value_name_int(
        0,
        "cash",
        s_CharacterCash[playerid]
    );

    cache_get_value_name_int(
        0,
        "bank",
        s_CharacterBank[playerid]
    );

    cache_get_value_name_int(
        0,
        "level",
        s_CharacterLevel[playerid]
    );

    cache_get_value_name_float(
        0,
        "health",
        s_CharacterHealth[playerid]
    );

    cache_get_value_name_float(
        0,
        "armour",
        s_CharacterArmour[playerid]
    );

    cache_get_value_name_float(
        0,
        "pos_x",
        s_CharacterPosX[playerid]
    );

    cache_get_value_name_float(
        0,
        "pos_y",
        s_CharacterPosY[playerid]
    );

    cache_get_value_name_float(
        0,
        "pos_z",
        s_CharacterPosZ[playerid]
    );

    cache_get_value_name_float(
        0,
        "pos_a",
        s_CharacterPosA[playerid]
    );

    cache_get_value_name_int(
        0,
        "interior_id",
        s_CharacterInterior[playerid]
    );

    cache_get_value_name_int(
        0,
        "virtual_world",
        s_CharacterVirtualWorld[playerid]
    );

    s_CharacterLoaded[playerid] = true;

    if (s_UICreatorPending[playerid] && s_CharacterCreated[playerid])
    {
        s_UICreatorPending[playerid] = false;
        UI_Notify(playerid, "success", "Đã tạo nhân vật thành công.");
        UI_Close(playerid);
    }

    // Chua hoan tat ho so -> bat buoc vao Character Creator.
    if (!s_CharacterCreated[playerid])
    {
        CharacterCreator_Start(playerid);
        return 1;
    }
    
    Cinematic_StartSpawn(playerid);

    return 1;
}

//-----------------------------------------------------------------------------
// Dialogs
//-----------------------------------------------------------------------------

hook OnDialogResponse( playerid,dialogid,response,listitem,inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_CHARACTER_SELECT:
        {
            if (!response)
            {
                Kick(playerid);
                return 1;
            }

            if (listitem < 0 || listitem >= MAX_CHARACTER_SLOTS)
            {
                Character_ShowSelectionDialog(playerid);
                return 1;
            }

            s_SelectedCharacterSlot[playerid] = listitem + 1;

            if (s_CharacterSlotID[playerid][listitem]==INVALID_CHARACTER_ID)
            {
                Character_ShowNameDialog(playerid);
                return 1;
            }

            Character_LoadByID(    playerid,    s_CharacterSlotID[playerid][listitem]);

            return 1;
        }

        case DIALOG_CHARACTER_NAME:
        {
            if (!response)
            {
                s_SelectedCharacterSlot[playerid] = 0;
                Cinematic_StartSelector(playerid);
                return 1;
            }
        
            if (!IsValidCharacterName(inputtext))
            {
                Character_ShowNameDialog(playerid, true, false);
                return 1;
            }
        
            Character_CheckName(playerid, inputtext);
            return 1;
        }
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Spawn
//-----------------------------------------------------------------------------

hook OnPlayerSpawn(playerid)
{
     if (!IsPlayerCharacterLoaded(playerid))
    {
        return 1;
    }

    if (s_CinematicLoginPreparing[playerid])
    {
        Cinematic_PrepareLoginPlayer(playerid);
        return 1;
    }

    if (Cinematic_IsSpawnActive(playerid))
    {
        Cinematic_PreparePlayer(playerid);
        return 1;
    }

    if (CharacterCreator_IsActive(playerid))
    {
        CharacterCreator_ApplyWorld(playerid);
        return 1;
    }
    SetPlayerSkin(
        playerid,
        s_CharacterSkin[playerid]
    );

    ResetPlayerMoney(playerid);

    GivePlayerMoney(
        playerid,
        s_CharacterCash[playerid]
    );

    SetPlayerScore(
        playerid,
        s_CharacterLevel[playerid]
    );

    SetPlayerHealth(
        playerid,
        s_CharacterHealth[playerid]
    );

    SetPlayerArmour(
        playerid,
        s_CharacterArmour[playerid]
    );

    // Development spawn: Ganton
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);

    SetPlayerPos(
        playerid,
        GANTON_SPAWN_X,
        GANTON_SPAWN_Y,
        GANTON_SPAWN_Z
    );

    SetPlayerFacingAngle(
        playerid,
        GANTON_SPAWN_A
    );

    TogglePlayerControllable(
        playerid,
        true
    );

    SetCameraBehindPlayer(playerid);

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        "Chao mung den voi Los Santos Roleplay."
    );

    return 1;
}

//-----------------------------------------------------------------------------
// Disconnect
//-----------------------------------------------------------------------------

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    if (s_CharacterLoaded[playerid])
    {
        Character_Save(playerid);
    }

    Character_Reset(playerid);
    return 1;
}
