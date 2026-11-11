#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// LS:RP Character Selector
//-----------------------------------------------------------------------------

#define SELECTOR_BORDER              (0x0B3D27FF)
#define SELECTOR_PANEL               (0x080C0AFF)
#define SELECTOR_HEADER              (0x0D120FFF)
#define SELECTOR_CARD                (0x1B231EFF)
#define SELECTOR_CARD_SELECTED       (0x123E2AFF)
#define SELECTOR_FOOTER              (0x141B17FF)

#define SELECTOR_WHITE               (0xE8EFEAFF)
#define SELECTOR_BUTTON_TEXT         (0xF3F7F4FF)
#define SELECTOR_GREY                (0x8E9D95FF)
#define SELECTOR_GREEN               (0x0B4A2EFF)
#define SELECTOR_GREEN_LIGHT         (0x1B7048FF)
#define SELECTOR_DISABLED            (0x303A35FF)

#define SELECTOR_HOVER               (0x25875AFF)

#define SELECTOR_SLOT_COUNT          (3)

new PlayerText:s_SelectorPanel[MAX_PLAYERS];
new PlayerText:s_SelectorSurface[MAX_PLAYERS];
new PlayerText:s_SelectorHeader[MAX_PLAYERS];
new PlayerText:s_SelectorAccent[MAX_PLAYERS];
new PlayerText:s_SelectorTitle[MAX_PLAYERS];
new PlayerText:s_SelectorSectionTitle[MAX_PLAYERS];

new PlayerText:s_SelectorFrame[MAX_PLAYERS][SELECTOR_SLOT_COUNT];
new PlayerText:s_SelectorSlotLabel[MAX_PLAYERS][SELECTOR_SLOT_COUNT];
new PlayerText:s_SelectorPreview[MAX_PLAYERS][SELECTOR_SLOT_COUNT];
new PlayerText:s_SelectorEmpty[MAX_PLAYERS][SELECTOR_SLOT_COUNT];

new PlayerText:s_SelectorFooter[MAX_PLAYERS];
new PlayerText:s_SelectorNameCaption[MAX_PLAYERS];
new PlayerText:s_SelectorName[MAX_PLAYERS];

new PlayerText:s_SelectorInfoButton[MAX_PLAYERS];
new PlayerText:s_SelectorPlayButton[MAX_PLAYERS];
new PlayerText:s_SelectorDeleteButton[MAX_PLAYERS];

new PlayerText:s_SelectorInfoPanel[MAX_PLAYERS];
new PlayerText:s_SelectorInfoText[MAX_PLAYERS];
new PlayerText:s_SelectorInfoClose[MAX_PLAYERS];

new bool:s_SelectorReady[MAX_PLAYERS];
new bool:s_SelectorVisible[MAX_PLAYERS];
new bool:s_SelectorInfoVisible[MAX_PLAYERS];

forward OnCharacterSelectorInfoLoaded(playerid);

//-----------------------------------------------------------------------------
// Text helpers
//-----------------------------------------------------------------------------

stock PlayerText:Selector_CreateText(playerid, Float:x, Float:y, const text[], color = SELECTOR_WHITE, Float:sx = 0.22, Float:sy = 1.0)
{
    new PlayerText:td = CreatePlayerTextDraw(playerid, x, y, text);

    PlayerTextDrawFont(playerid, td, TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, td, sx, sy);
    PlayerTextDrawColor(playerid, td, color);

    PlayerTextDrawBackgroundColor(playerid, td, 0x000000FF);
    PlayerTextDrawSetOutline(playerid, td, 1);
    PlayerTextDrawSetShadow(playerid, td, 0);
    PlayerTextDrawSetProportional(playerid, td, true);

    return td;
}

stock PlayerText:Selector_CreateButton(
    playerid,
    Float:x,
    Float:y,
    const text[],
    boxColor,
    Float:width = 118.0)
{
    new PlayerText:td = Selector_CreateText(playerid, x, y, text, SELECTOR_BUTTON_TEXT, 0.19, 1.0);

    PlayerTextDrawAlignment(playerid, td, TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawUseBox(playerid, td, true);
    PlayerTextDrawBoxColor(playerid, td, boxColor);

    PlayerTextDrawTextSize(playerid, td, 13.0, width);
    PlayerTextDrawSetSelectable(playerid, td, true);

    return td;
}

//-----------------------------------------------------------------------------
// Area name
//-----------------------------------------------------------------------------

CharacterSelector_GetLocationName(Float:x, Float:y, output[], size)
{
    if (x >= 2220.0 && x <= 2630.0 && y >= -1900.0 && y <= -1500.0)
    {
        format(output, size, "Ganton, Los Santos");
    }
    else if (x >= 1810.0 && x <= 2150.0 && y >= -1900.0 && y <= -1580.0)
    {
        format(output, size, "Idlewood, Los Santos");
    }
    else if (x >= 1980.0 && x <= 2300.0 && y >= -1600.0 && y <= -1250.0)
    {
        format(output, size, "Jefferson, Los Santos");
    }
    else if (x >= 1250.0 && x <= 1800.0 && y >= -1850.0 && y <= -1350.0)
    {
        format(output, size, "Trung tam Los Santos");
    }
    else
    {
        format(output, size, "Los Santos");
    }

    return 1;
}

//-----------------------------------------------------------------------------
// UI creation
//-----------------------------------------------------------------------------

CharacterSelector_CreateUI(playerid)
{
    if (s_SelectorReady[playerid])
    {
        return 1;
    }

    // Dark green outer frame.
    s_SelectorPanel[playerid] = CreatePlayerTextDraw(playerid, 80.0, 61.0, "_");
    PlayerTextDrawLetterSize(playerid, s_SelectorPanel[playerid], 0.0, 32.4);
    PlayerTextDrawTextSize(playerid, s_SelectorPanel[playerid], 560.0, 0.0);
    PlayerTextDrawUseBox(playerid, s_SelectorPanel[playerid], true);
    PlayerTextDrawBoxColor(playerid, s_SelectorPanel[playerid], SELECTOR_BORDER);

    // Inner surface and dashboard header.
    s_SelectorSurface[playerid] = CreatePlayerTextDraw(playerid, 84.0, 65.0, "_");
    PlayerTextDrawLetterSize(playerid, s_SelectorSurface[playerid], 0.0, 31.6);
    PlayerTextDrawTextSize(playerid, s_SelectorSurface[playerid], 556.0, 0.0);
    PlayerTextDrawUseBox(playerid, s_SelectorSurface[playerid], true);
    PlayerTextDrawBoxColor(playerid, s_SelectorSurface[playerid], SELECTOR_PANEL);

    s_SelectorHeader[playerid] = CreatePlayerTextDraw(playerid, 84.0, 65.0, "_");
    PlayerTextDrawLetterSize(playerid, s_SelectorHeader[playerid], 0.0, 4.2);
    PlayerTextDrawTextSize(playerid, s_SelectorHeader[playerid], 556.0, 0.0);
    PlayerTextDrawUseBox(playerid, s_SelectorHeader[playerid], true);
    PlayerTextDrawBoxColor(playerid, s_SelectorHeader[playerid], SELECTOR_HEADER);

    s_SelectorAccent[playerid] = CreatePlayerTextDraw(playerid, 84.0, 103.0, "_");
    PlayerTextDrawLetterSize(playerid, s_SelectorAccent[playerid], 0.0, 0.45);
    PlayerTextDrawTextSize(playerid, s_SelectorAccent[playerid], 556.0, 0.0);
    PlayerTextDrawUseBox(playerid, s_SelectorAccent[playerid], true);
    PlayerTextDrawBoxColor(playerid, s_SelectorAccent[playerid], SELECTOR_GREEN_LIGHT);

    s_SelectorTitle[playerid] = Selector_CreateText(playerid, 320.0, 74.0, "LOS SANTOS ROLEPLAY", SELECTOR_WHITE, 0.28, 1.20);
    PlayerTextDrawFont(playerid, s_SelectorTitle[playerid], TEXT_DRAW_FONT_3);
    PlayerTextDrawAlignment(playerid, s_SelectorTitle[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawSetOutline(playerid, s_SelectorTitle[playerid], 2);

    s_SelectorSectionTitle[playerid] = Selector_CreateText(playerid, 537.0, 77.0, "CHARACTER SELECTION", SELECTOR_GREY, 0.18, 0.95);
    PlayerTextDrawAlignment(playerid, s_SelectorSectionTitle[playerid], TEXT_DRAW_ALIGN_RIGHT);

    new const Float:slotX[3] = {102.0, 252.0, 402.0};

    for (new slot = 0; slot < SELECTOR_SLOT_COUNT; slot++)
    {
        // Character card.
        s_SelectorFrame[playerid][slot] = CreatePlayerTextDraw(playerid, slotX[slot], 122.0, "_");
        PlayerTextDrawLetterSize(playerid, s_SelectorFrame[playerid][slot], 0.0, 15.0);
        PlayerTextDrawTextSize(playerid, s_SelectorFrame[playerid][slot], slotX[slot] + 136.0, 0.0);
        PlayerTextDrawUseBox(playerid, s_SelectorFrame[playerid][slot], true);
        PlayerTextDrawBoxColor(playerid, s_SelectorFrame[playerid][slot], SELECTOR_CARD);

        new slotText[16];
        format(slotText, sizeof(slotText), "SLOT %02d", slot + 1);
        s_SelectorSlotLabel[playerid][slot] = Selector_CreateText(
            playerid,
            slotX[slot] + 10.0,
            131.0,
            slotText,
            SELECTOR_GREY,
            0.18,
            0.85
        );

        // Skin model preview.
        s_SelectorPreview[playerid][slot] = CreatePlayerTextDraw(playerid, slotX[slot] + 5.0, 145.0, "_");
        PlayerTextDrawFont(playerid, s_SelectorPreview[playerid][slot], TEXT_DRAW_FONT_MODEL_PREVIEW);
        PlayerTextDrawTextSize(playerid, s_SelectorPreview[playerid][slot], 126.0, 118.0);
        PlayerTextDrawColor(playerid, s_SelectorPreview[playerid][slot], 0xFFFFFFFF);
        PlayerTextDrawBackgroundColor(playerid, s_SelectorPreview[playerid][slot], 0x00000000);
        PlayerTextDrawUseBox(playerid, s_SelectorPreview[playerid][slot], false);
        PlayerTextDrawSetPreviewModel(playerid, s_SelectorPreview[playerid][slot], 26);
        PlayerTextDrawSetPreviewRot(playerid, s_SelectorPreview[playerid][slot], -10.0, 0.0, -20.0, 1.25);
        PlayerTextDrawSetSelectable(playerid, s_SelectorPreview[playerid][slot], true);

        // Empty slot.
        s_SelectorEmpty[playerid][slot] = Selector_CreateText(playerid, slotX[slot] + 68.0, 189.0, "EMPTY SLOT~n~~g~+ CREATE", SELECTOR_GREY, 0.18, 0.95);
        PlayerTextDrawAlignment(playerid, s_SelectorEmpty[playerid][slot], TEXT_DRAW_ALIGN_CENTER);
        PlayerTextDrawTextSize(playerid, s_SelectorEmpty[playerid][slot], 90.0, 122.0);
        PlayerTextDrawSetSelectable(playerid, s_SelectorEmpty[playerid][slot], true);
    }

    // Selected character summary.
    s_SelectorFooter[playerid] = CreatePlayerTextDraw(playerid, 102.0, 284.0, "_");
    PlayerTextDrawLetterSize(playerid, s_SelectorFooter[playerid], 0.0, 3.6);
    PlayerTextDrawTextSize(playerid, s_SelectorFooter[playerid], 538.0, 0.0);
    PlayerTextDrawUseBox(playerid, s_SelectorFooter[playerid], true);
    PlayerTextDrawBoxColor(playerid, s_SelectorFooter[playerid], SELECTOR_FOOTER);

    s_SelectorNameCaption[playerid] = Selector_CreateText(playerid, 320.0, 293.0, "SELECTED CHARACTER", SELECTOR_GREEN_LIGHT, 0.16, 0.75);
    PlayerTextDrawAlignment(playerid, s_SelectorNameCaption[playerid], TEXT_DRAW_ALIGN_CENTER);
    s_SelectorName[playerid] = Selector_CreateText(playerid, 320.0, 307.0, "Chon mot nhan vat", SELECTOR_WHITE, 0.22, 1.0);
    PlayerTextDrawAlignment(playerid, s_SelectorName[playerid], TEXT_DRAW_ALIGN_CENTER);

    s_SelectorInfoButton[playerid] = Selector_CreateButton(playerid, 175.0, 329.0, "THONG TIN", SELECTOR_GREEN);
    s_SelectorPlayButton[playerid] = Selector_CreateButton(playerid, 320.0, 329.0, "VAO GAME", SELECTOR_GREEN_LIGHT);
    s_SelectorDeleteButton[playerid] = Selector_CreateButton(playerid, 465.0, 329.0, "CHUA HO TRO", SELECTOR_DISABLED);

    // Info overlay.
    s_SelectorInfoPanel[playerid] = CreatePlayerTextDraw(playerid, 150.0, 126.0, "_");
    PlayerTextDrawLetterSize(playerid, s_SelectorInfoPanel[playerid], 0.0, 22.3);
    PlayerTextDrawTextSize(playerid, s_SelectorInfoPanel[playerid], 490.0, 0.0);
    PlayerTextDrawUseBox(playerid, s_SelectorInfoPanel[playerid], true);
    PlayerTextDrawBoxColor(playerid, s_SelectorInfoPanel[playerid], SELECTOR_CARD);

    s_SelectorInfoText[playerid] = Selector_CreateText(playerid, 174.0, 143.0, "Dang tai thong tin...", SELECTOR_WHITE, 0.19, 0.95);

    s_SelectorInfoClose[playerid] = Selector_CreateButton(playerid, 320.0, 340.0, "QUAY LAI", SELECTOR_GREEN_LIGHT, 150.0);

    s_SelectorReady[playerid] = true;
    return 1;
}

//-----------------------------------------------------------------------------
// Refresh slots
//-----------------------------------------------------------------------------

CharacterSelector_Refresh(playerid)
{
    CharacterSelector_CreateUI(playerid);

    for (new slot = 0; slot < SELECTOR_SLOT_COUNT; slot++)
    {
        PlayerTextDrawHide(playerid, s_SelectorFrame[playerid][slot]);

        if (s_SelectedCharacterSlot[playerid] == slot + 1)
        {
            PlayerTextDrawBoxColor(playerid, s_SelectorFrame[playerid][slot], SELECTOR_CARD_SELECTED);
            PlayerTextDrawColor(playerid, s_SelectorSlotLabel[playerid][slot], SELECTOR_WHITE);
        }
        else
        {
            PlayerTextDrawBoxColor(playerid, s_SelectorFrame[playerid][slot], SELECTOR_CARD);
            PlayerTextDrawColor(playerid, s_SelectorSlotLabel[playerid][slot], SELECTOR_GREY);
        }

        PlayerTextDrawShow(playerid, s_SelectorFrame[playerid][slot]);
        PlayerTextDrawShow(playerid, s_SelectorSlotLabel[playerid][slot]);

        if (s_CharacterSlotID[playerid][slot] == INVALID_CHARACTER_ID)
        {
            PlayerTextDrawHide(playerid, s_SelectorPreview[playerid][slot]);
            PlayerTextDrawShow(playerid, s_SelectorEmpty[playerid][slot]);
        }
        else
        {
            PlayerTextDrawHide(playerid, s_SelectorEmpty[playerid][slot]);

            PlayerTextDrawSetPreviewModel(playerid,
                s_SelectorPreview[playerid][slot],
                s_CharacterSlotSkin[playerid][slot]
            );

            PlayerTextDrawShow(playerid, s_SelectorPreview[playerid][slot]);
        }
    }

    if (s_SelectedCharacterSlot[playerid] >= 1 && s_SelectedCharacterSlot[playerid] <= 3)
    {
        new const index = s_SelectedCharacterSlot[playerid] - 1;

        if (s_CharacterSlotID[playerid][index] != INVALID_CHARACTER_ID)
        {
            PlayerTextDrawSetString(playerid, s_SelectorName[playerid], s_CharacterSlotName[playerid][index]);
        }
        else
        {
            PlayerTextDrawSetString(playerid, s_SelectorName[playerid], "Slot trong - Khoi tao nhan vat");
        }
    }
    else
    {
        PlayerTextDrawSetString(playerid, s_SelectorName[playerid], "Chon mot nhan vat");
    }

    return 1;
}

//-----------------------------------------------------------------------------
// Open / Close
//-----------------------------------------------------------------------------

CharacterSelector_OpenUI(playerid)
{
    if (UI_UseCEF(playerid))
    {
        Cinematic_StopSelector(playerid);
        UI_Show(playerid, UI_SLOTS);
        return 1;
    }
    CharacterSelector_CreateUI(playerid);

    s_SelectorVisible[playerid] = true;
    s_SelectorInfoVisible[playerid] = false;

    PlayerTextDrawShow(playerid, s_SelectorPanel[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorSurface[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorHeader[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorAccent[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorTitle[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorSectionTitle[playerid]);

    CharacterSelector_Refresh(playerid);

    PlayerTextDrawShow(playerid, s_SelectorFooter[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorNameCaption[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorName[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorInfoButton[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorPlayButton[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorDeleteButton[playerid]);

    SelectTextDraw(playerid, SELECTOR_HOVER);
    return 1;
}

CharacterSelector_CloseUI(playerid)
{
    UI_Close(playerid);
    if (!s_SelectorReady[playerid])
    {
        return 1;
    }

    CancelSelectTextDraw(playerid);

    PlayerTextDrawHide(playerid, s_SelectorPanel[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorSurface[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorHeader[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorAccent[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorTitle[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorSectionTitle[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorFooter[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorNameCaption[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorName[playerid]);

    PlayerTextDrawHide(playerid, s_SelectorInfoButton[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorPlayButton[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorDeleteButton[playerid]);

    PlayerTextDrawHide(playerid, s_SelectorInfoPanel[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorInfoText[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorInfoClose[playerid]);

    for (new slot = 0; slot < SELECTOR_SLOT_COUNT; slot++)
    {
        PlayerTextDrawHide(playerid, s_SelectorFrame[playerid][slot]);
        PlayerTextDrawHide(playerid, s_SelectorSlotLabel[playerid][slot]);
        PlayerTextDrawHide(playerid, s_SelectorPreview[playerid][slot]);
        PlayerTextDrawHide(playerid, s_SelectorEmpty[playerid][slot]);
    }

    s_SelectorVisible[playerid] = false;
    s_SelectorInfoVisible[playerid] = false;

    return 1;
}

//-----------------------------------------------------------------------------
// Slot select
//-----------------------------------------------------------------------------

CharacterSelector_SelectSlot(playerid, slotIndex)
{
    if (slotIndex < 0 || slotIndex >= MAX_CHARACTER_SLOTS)
    {
        return 0;
    }

    s_SelectedCharacterSlot[playerid] = slotIndex + 1;

    // Empty slot -> existing character creation flow.
    if (s_CharacterSlotID[playerid][slotIndex] == INVALID_CHARACTER_ID)
    {
        CharacterSelector_CloseUI(playerid);
        Cinematic_StopSelector(playerid);

        Character_ShowNameDialog(playerid);
        return 1;
    }

    if (UI_UseCEF(playerid)) UI_Show(playerid, UI_SLOTS);
    else CharacterSelector_Refresh(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Information
//-----------------------------------------------------------------------------

CharacterSelector_RequestInfo(playerid)
{
    if (s_SelectedCharacterSlot[playerid] < 1 || s_SelectedCharacterSlot[playerid] > 3)
    {
        SendClientMessage(playerid, COLOR_RED, "Hay chon mot nhan vat truoc.");
        return 0;
    }

    new const index = s_SelectedCharacterSlot[playerid] - 1;
    new const characterID = s_CharacterSlotID[playerid][index];

    if (characterID == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    new query[1024];

    mysql_format(g_DatabaseHandle, query, sizeof(query),
        "SELECT `name`,`gender`,`birth_day`,`birth_month`,`birth_year`,`skin_tone`,`voice`,`height_cm`,`weight_kg`,`birth_place`,`level`,`cash`,`bank`,`pos_x`,`pos_y`,`pos_z`,`last_played` FROM `player_characters` WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;",
        characterID,
        GetPlayerAccountID(playerid)
    );

    mysql_tquery(g_DatabaseHandle, query, "OnCharacterSelectorInfoLoaded", "d", playerid);
    return 1;
}

public OnCharacterSelectorInfoLoaded(playerid)
{
    if (!IsPlayerConnected(playerid) || cache_num_rows() == 0)
    {
        return 1;
    }

    new
        name[25],
        gender,
        day,
        month,
        year,
        tone,
        voice,
        height,
        weight,
        birthPlace,
        level,
        cash,
        bank;

    new
        Float:x,
        Float:y,
        Float:z;

    new lastPlayed[32];
    new location[64];
    new body[768];

    cache_get_value_name(0, "name", name, sizeof(name));

    cache_get_value_name_int(0, "gender", gender);
    cache_get_value_name_int(0, "birth_day", day);
    cache_get_value_name_int(0, "birth_month", month);
    cache_get_value_name_int(0, "birth_year", year);

    cache_get_value_name_int(0, "skin_tone", tone);
    cache_get_value_name_int(0, "voice", voice);
    cache_get_value_name_int(0, "height_cm", height);
    cache_get_value_name_int(0, "weight_kg", weight);
    cache_get_value_name_int(0, "birth_place", birthPlace);

    cache_get_value_name_int(0, "level", level);
    cache_get_value_name_int(0, "cash", cash);
    cache_get_value_name_int(0, "bank", bank);

    cache_get_value_name_float(0, "pos_x", x);
    cache_get_value_name_float(0, "pos_y", y);
    cache_get_value_name_float(0, "pos_z", z);

    cache_get_value_name(0, "last_played", lastPlayed, sizeof(lastPlayed));

    CharacterSelector_GetLocationName(x, y, location, sizeof(location));

    new genderName[8];

    if (gender == 0)
    {
        format(genderName, sizeof(genderName), "Nam");
    }
    else
    {
        format(genderName, sizeof(genderName), "Nu");
    }

   format(body, sizeof(body), "~g~THONG TIN NHAN VAT~w~~n~~n~Ho ten: ~g~%s~w~~n~Gioi tinh: ~g~%s~w~~n~Ngay sinh: ~g~%02d/%02d/%d~w~~n~Tuoi: ~g~%d~w~~n~Chieu cao: ~g~%d cm~w~~n~Can nang: ~g~%d kg~w~~n~Mau da: ~g~%s~w~~n~Noi sinh: ~g~%s~w~~n~~n~Cap do: ~g~%d~w~~n~Tien mat: ~g~$%d~w~~n~Ngan hang: ~g~$%d~w~~n~~n~Vi tri cuoi: ~g~%s~w~~n~Lan cuoi choi: ~g~%s",
    name,
    genderName,
    day,
    month,
    year,
    GAME_CONTEXT_YEAR - year,
    height,
    weight,
    g_SkinToneNames[tone],
    g_BirthPlaceNames[birthPlace],
    level,
    cash,
    bank,
    location,
    lastPlayed
);

    CharacterSelector_CloseMainElements(playerid);

    PlayerTextDrawSetString(playerid, s_SelectorInfoText[playerid], body);

    PlayerTextDrawShow(playerid, s_SelectorInfoPanel[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorInfoText[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorInfoClose[playerid]);

    SelectTextDraw(playerid, SELECTOR_HOVER);

    s_SelectorInfoVisible[playerid] = true;
    return 1;
}

CharacterSelector_CloseMainElements(playerid)
{
    PlayerTextDrawHide(playerid, s_SelectorFooter[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorNameCaption[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorName[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorInfoButton[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorPlayButton[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorDeleteButton[playerid]);

    for (new slot = 0; slot < SELECTOR_SLOT_COUNT; slot++)
    {
        PlayerTextDrawHide(playerid, s_SelectorFrame[playerid][slot]);
        PlayerTextDrawHide(playerid, s_SelectorSlotLabel[playerid][slot]);
        PlayerTextDrawHide(playerid, s_SelectorPreview[playerid][slot]);
        PlayerTextDrawHide(playerid, s_SelectorEmpty[playerid][slot]);
    }

    return 1;
}

CharacterSelector_CloseInfo(playerid)
{
    PlayerTextDrawHide(playerid, s_SelectorInfoPanel[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorInfoText[playerid]);
    PlayerTextDrawHide(playerid, s_SelectorInfoClose[playerid]);

    s_SelectorInfoVisible[playerid] = false;

    CharacterSelector_Refresh(playerid);

    PlayerTextDrawShow(playerid, s_SelectorFooter[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorNameCaption[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorName[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorInfoButton[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorPlayButton[playerid]);
    PlayerTextDrawShow(playerid, s_SelectorDeleteButton[playerid]);

    SelectTextDraw(playerid, SELECTOR_HOVER);
    return 1;
}

//-----------------------------------------------------------------------------
// Play
//-----------------------------------------------------------------------------

CharacterSelector_Play(playerid)
{
    if (s_SelectedCharacterSlot[playerid] < 1 || s_SelectedCharacterSlot[playerid] > 3)
    {
        SendClientMessage(playerid, COLOR_RED, "Hay chon mot nhan vat truoc.");
        return 0;
    }

    new const index = s_SelectedCharacterSlot[playerid] - 1;
    new const characterID = s_CharacterSlotID[playerid][index];

    if (characterID == INVALID_CHARACTER_ID)
    {
        SendClientMessage(playerid, COLOR_RED, "Slot nay chua co nhan vat.");
        return 0;
    }

    CharacterSelector_CloseUI(playerid);
    Cinematic_StopSelector(playerid);

    // OnCharacterLoaded se tiep tuc bang Cinematic_StartSpawn.
    Character_LoadByID(playerid, characterID);

    return 1;
}

//-----------------------------------------------------------------------------
// Click
//-----------------------------------------------------------------------------

hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if (!s_SelectorVisible[playerid])
    {
        return 0;
    }

    if (s_SelectorInfoVisible[playerid])
    {
        if (playertextid == s_SelectorInfoClose[playerid])
        {
            CharacterSelector_CloseInfo(playerid);
            return 1;
        }

        return 1;
    }

    for (new slot = 0; slot < SELECTOR_SLOT_COUNT; slot++)
    {
        if (playertextid == s_SelectorPreview[playerid][slot] ||
            playertextid == s_SelectorEmpty[playerid][slot])
        {
            CharacterSelector_SelectSlot(playerid, slot);
            return 1;
        }
    }

    if (playertextid == s_SelectorInfoButton[playerid])
    {
        CharacterSelector_RequestInfo(playerid);
        return 1;
    }

    if (playertextid == s_SelectorPlayButton[playerid])
    {
        CharacterSelector_Play(playerid);
        return 1;
    }

    if (playertextid == s_SelectorDeleteButton[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Tinh nang xoa nhan vat hien chua duoc mo.");
        return 1;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Cleanup
//-----------------------------------------------------------------------------

hook OnPlayerConnect(playerid)
{
    s_SelectorReady[playerid] = false;
    s_SelectorVisible[playerid] = false;
    s_SelectorInfoVisible[playerid] = false;

    s_SelectedCharacterSlot[playerid] = 0;

    return 1;
}
