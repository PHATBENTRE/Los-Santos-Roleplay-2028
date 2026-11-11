#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// LS:RP Character Creator
//-----------------------------------------------------------------------------

#define CREATOR_INTERIOR             (3)
#define CREATOR_WORLD_BASE           (15000)

// Johnson House
#define CREATOR_POS_X                (2496.0549)
#define CREATOR_POS_Y                (-1693.6500)
#define CREATOR_POS_Z                (1014.7422)
#define CREATOR_POS_A                (180.0)

#define CREATOR_CAMERA_X             (2496.0549)
#define CREATOR_CAMERA_Y             (-1696.6000)
#define CREATOR_CAMERA_Z             (1015.5500)

#define CREATOR_CAMERA_LOOK_X        (2496.0549)
#define CREATOR_CAMERA_LOOK_Y        (-1693.6500)
#define CREATOR_CAMERA_LOOK_Z        (1015.3500)

#define CREATOR_SKINS_PER_GROUP      (6)

#define CREATOR_COLOR_WHITE          (0xE8EFEAFF)
#define CREATOR_COLOR_LIGHT          (0xF3F7F4FF)
#define CREATOR_COLOR_GREY           (0x8E9D95FF)
#define CREATOR_COLOR_GREEN          (0x39A06BFF)
#define CREATOR_COLOR_BORDER         (0x0B3D27FF)
#define CREATOR_COLOR_PANEL          (0x080C0AFF)
#define CREATOR_COLOR_HEADER         (0x0D120FFF)
#define CREATOR_COLOR_CONTENT        (0x111713FF)
#define CREATOR_COLOR_ROW            (0x1B231EFF)
#define CREATOR_COLOR_ROW_ALT        (0x202A24FF)
#define CREATOR_COLOR_BUTTON         (0x0B4A2EFF)
#define CREATOR_COLOR_ACCENT         (0x1B7048FF)
#define CREATOR_COLOR_HOVER          (0x25875AFF)

//-----------------------------------------------------------------------------
// Skin groups
// gender -> skin tone -> skins
//-----------------------------------------------------------------------------

new const g_CreatorSkins[2][3][CREATOR_SKINS_PER_GROUP] =
{
    // Nam
    {
        {20, 46, 98, 147, 186, 187},
        {28, 29, 47, 48, 60, 120},
        {7, 21, 22, 25, 26, 67}
    },

    // Nu
    {
        {12, 40, 41, 55, 56, 91},
        {13, 69, 76, 89, 138, 139},
        {9, 10, 11, 63, 64, 190}
    }
};

new const g_SkinToneNames[][] =
{
    "Sang",
    "Trung binh",
    "Toi"
};

new const g_BirthPlaceNames[][] =
{
    "Los Santos",
    "San Fierro",
    "Las Venturas",
    "Noi khac"
};

new const g_MaleVoiceNames[][] =
{
    "Tram",
    "Trung",
    "Tre",
    "Khan"
};

new const g_FemaleVoiceNames[][] =
{
    "Diu",
    "Trung",
    "Tre",
    "Tram"
};

//-----------------------------------------------------------------------------
// Player TextDraws
//-----------------------------------------------------------------------------
enum
{
    CreatorTD_Panel,
    CreatorTD_Surface,
    CreatorTD_Header,
    CreatorTD_Accent,
    CreatorTD_ContentPanel,
    CreatorTD_NamePanel,

    CreatorTD_GenderRow,
    CreatorTD_DayRow,
    CreatorTD_MonthRow,
    CreatorTD_YearRow,
    CreatorTD_ToneRow,
    CreatorTD_SkinRow,
    CreatorTD_VoiceRow,
    CreatorTD_HeightRow,
    CreatorTD_WeightRow,
    CreatorTD_BirthPlaceRow,

    CreatorTD_Title,
    CreatorTD_Subtitle,
    CreatorTD_Name,

    CreatorTD_GenderLabel,
    CreatorTD_GenderLeft,
    CreatorTD_GenderValue,
    CreatorTD_GenderRight,

    CreatorTD_DayLabel,
    CreatorTD_DayLeft,
    CreatorTD_DayValue,
    CreatorTD_DayRight,

    CreatorTD_MonthLabel,
    CreatorTD_MonthLeft,
    CreatorTD_MonthValue,
    CreatorTD_MonthRight,

    CreatorTD_YearLabel,
    CreatorTD_YearLeft,
    CreatorTD_YearValue,
    CreatorTD_YearRight,

    CreatorTD_ToneLabel,
    CreatorTD_ToneLeft,
    CreatorTD_ToneValue,
    CreatorTD_ToneRight,

    CreatorTD_SkinLabel,
    CreatorTD_SkinLeft,
    CreatorTD_SkinValue,
    CreatorTD_SkinRight,

    CreatorTD_VoiceLabel,
    CreatorTD_VoiceLeft,
    CreatorTD_VoiceValue,
    CreatorTD_VoiceRight,

    CreatorTD_HeightLabel,
    CreatorTD_HeightLeft,
    CreatorTD_HeightValue,
    CreatorTD_HeightRight,

    CreatorTD_WeightLabel,
    CreatorTD_WeightLeft,
    CreatorTD_WeightValue,
    CreatorTD_WeightRight,

    CreatorTD_BirthPlaceLabel,
    CreatorTD_BirthPlaceLeft,
    CreatorTD_BirthPlaceValue,
    CreatorTD_BirthPlaceRight,

    CreatorTD_Hint,
    CreatorTD_Confirm,

    CreatorTD_Count
};

new PlayerText:s_CreatorTD[MAX_PLAYERS][CreatorTD_Count];

new
    bool:s_CreatorActive[MAX_PLAYERS],
    bool:s_CreatorUIReady[MAX_PLAYERS],
    bool:s_CreatorSaving[MAX_PLAYERS],
    s_CreatorSkinIndex[MAX_PLAYERS];

//-----------------------------------------------------------------------------
// Callback
//-----------------------------------------------------------------------------

forward public OnCharacterCreatorSaved(playerid);

//-----------------------------------------------------------------------------
// Helpers
//-----------------------------------------------------------------------------

stock Creator_Wrap(value, minimum, maximum, change)
{
    value += change;

    if (value < minimum)
    {
        value = maximum;
    }
    else if (value > maximum)
    {
        value = minimum;
    }

    return value;
}

stock bool:Creator_IsLeapYear(year)
{
    if ((year % 400) == 0)
    {
        return true;
    }

    if ((year % 100) == 0)
    {
        return false;
    }

    return (year % 4) == 0;
}

stock Creator_GetDaysInMonth(month, year)
{
    switch (month)
    {
        case 2:
        {
            if (Creator_IsLeapYear(year))
            {
                return 29;
            }

            return 28;
        }

        case 4, 6, 9, 11:
        {
            return 30;
        }
    }

    return 31;
}

Creator_ClampBirthDay(playerid)
{
    new const maxDay = Creator_GetDaysInMonth(
        s_CharacterBirthMonth[playerid],
        s_CharacterBirthYear[playerid]
    );

    if (s_CharacterBirthDay[playerid] > maxDay)
    {
        s_CharacterBirthDay[playerid] = maxDay;
    }

    if (s_CharacterBirthDay[playerid] < 1)
    {
        s_CharacterBirthDay[playerid] = 1;
    }

    return 1;
}

Creator_FindSkinIndex(playerid)
{
    new
        gender = s_CharacterGender[playerid],
        tone = s_CharacterSkinTone[playerid];

    for (new i = 0; i < CREATOR_SKINS_PER_GROUP; i++)
    {
        if (g_CreatorSkins[gender][tone][i] == s_CharacterSkin[playerid])
        {
            return i;
        }
    }

    return 0;
}

Creator_ApplySkin(playerid)
{
    new
        gender = s_CharacterGender[playerid],
        tone = s_CharacterSkinTone[playerid],
        index = s_CreatorSkinIndex[playerid];

    s_CharacterSkin[playerid] =
        g_CreatorSkins[gender][tone][index];

    SetPlayerSkin(
        playerid,
        s_CharacterSkin[playerid]
    );

    return 1;
}

Creator_NormalizeProfile(playerid)
{
    if (s_CharacterGender[playerid] < 0 ||
        s_CharacterGender[playerid] > 1)
    {
        s_CharacterGender[playerid] = 0;
    }

    if (s_CharacterBirthMonth[playerid] < 1 ||
        s_CharacterBirthMonth[playerid] > 12)
    {
        s_CharacterBirthMonth[playerid] = 1;
    }

    if (s_CharacterBirthYear[playerid] < CHARACTER_MIN_BIRTH_YEAR ||
        s_CharacterBirthYear[playerid] > CHARACTER_MAX_BIRTH_YEAR)
    {
        s_CharacterBirthYear[playerid] = 1964;
    }

    if (s_CharacterSkinTone[playerid] < 0 ||
        s_CharacterSkinTone[playerid] > 2)
    {
        s_CharacterSkinTone[playerid] = 2;
    }

    if (s_CharacterVoice[playerid] < 0 ||
        s_CharacterVoice[playerid] > 3)
    {
        s_CharacterVoice[playerid] = 0;
    }

    if (s_CharacterHeight[playerid] < 150 ||
        s_CharacterHeight[playerid] > 210)
    {
        s_CharacterHeight[playerid] = 175;
    }

    if (s_CharacterWeight[playerid] < 45 ||
        s_CharacterWeight[playerid] > 150)
    {
        s_CharacterWeight[playerid] = 70;
    }

    if (s_CharacterBirthPlace[playerid] < 0 ||
        s_CharacterBirthPlace[playerid] > 3)
    {
        s_CharacterBirthPlace[playerid] = 0;
    }

    Creator_ClampBirthDay(playerid);

    // Pick a random skin from the selected gender and skin-tone group.
    s_CreatorSkinIndex[playerid] = random(CREATOR_SKINS_PER_GROUP);
    s_CharacterSkin[playerid] = g_CreatorSkins[
        s_CharacterGender[playerid]
    ][
        s_CharacterSkinTone[playerid]
    ][
        s_CreatorSkinIndex[playerid]
    ];

    Creator_ApplySkin(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// TextDraw creation
//-----------------------------------------------------------------------------

stock PlayerText:Creator_CreateText(
    playerid,
    Float:x,
    Float:y,
    const text[],
    color = CREATOR_COLOR_WHITE,
    Float:sizeX = 0.21,
    Float:sizeY = 0.95)
{
    new PlayerText:td =
        CreatePlayerTextDraw(playerid, x, y, text);

    PlayerTextDrawFont(playerid, td, TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, td, sizeX, sizeY);

    PlayerTextDrawColor(playerid, td, color);
    PlayerTextDrawBackgroundColor(playerid, td, 0x000000FF);

    PlayerTextDrawSetOutline(playerid, td, 1);
    PlayerTextDrawSetShadow(playerid, td, 0);

    PlayerTextDrawSetProportional(playerid, td, true);

    return td;
}

stock PlayerText:Creator_CreateArrow(playerid, Float:x, Float:y, const text[])
{
    new PlayerText:td = Creator_CreateText(playerid, x, y, text, CREATOR_COLOR_LIGHT, 0.20, 0.95);

    // Giảm vùng selectable để không chồng chéo
    PlayerTextDrawAlignment(playerid, td, TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawUseBox(playerid, td, true);
    PlayerTextDrawBoxColor(playerid, td, CREATOR_COLOR_BUTTON);
    PlayerTextDrawTextSize(playerid, td, 12.0, 22.0);
    PlayerTextDrawSetSelectable(playerid, td, true);

    return td;
}

stock PlayerText:Creator_CreateBox(
    playerid,
    Float:left,
    Float:top,
    Float:right,
    Float:height,
    color)
{
    new PlayerText:td = CreatePlayerTextDraw(playerid, left, top, "_");

    PlayerTextDrawLetterSize(playerid, td, 0.0, height);
    PlayerTextDrawTextSize(playerid, td, right, 0.0);
    PlayerTextDrawUseBox(playerid, td, true);
    PlayerTextDrawBoxColor(playerid, td, color);

    return td;
}

stock PlayerText:Creator_CreateValue(
    playerid,
    Float:x,
    Float:y,
    const text[],
    Float:sizeX = 0.19)
{
    new PlayerText:td = Creator_CreateText(
        playerid,
        x,
        y,
        text,
        CREATOR_COLOR_GREEN,
        sizeX,
        0.95
    );

    PlayerTextDrawAlignment(playerid, td, TEXT_DRAW_ALIGN_CENTER);
    return td;
}
Creator_CreateUI(playerid)
{
    if (s_CreatorUIReady[playerid])
    {
        return 1;
    }

    // =========================================================
    // PANEL NHO GON HON
    // =========================================================
    s_CreatorTD[playerid][CreatorTD_Panel] = Creator_CreateBox(
        playerid,
        386.0,
        25.0,
        628.0,
        40.8,
        CREATOR_COLOR_BORDER
    );

    s_CreatorTD[playerid][CreatorTD_Surface] = Creator_CreateBox(
        playerid,
        390.0,
        29.0,
        624.0,
        40.0,
        CREATOR_COLOR_PANEL
    );

    s_CreatorTD[playerid][CreatorTD_Header] = Creator_CreateBox(
        playerid,
        390.0,
        29.0,
        624.0,
        5.8,
        CREATOR_COLOR_HEADER
    );

    s_CreatorTD[playerid][CreatorTD_Accent] = Creator_CreateBox(
        playerid,
        390.0,
        84.0,
        624.0,
        0.45,
        CREATOR_COLOR_ACCENT
    );

    s_CreatorTD[playerid][CreatorTD_ContentPanel] = Creator_CreateBox(
        playerid,
        390.0,
        89.0,
        624.0,
        33.5,
        CREATOR_COLOR_CONTENT
    );

    s_CreatorTD[playerid][CreatorTD_NamePanel] = Creator_CreateBox(
        playerid,
        403.0,
        95.0,
        611.0,
        2.5,
        CREATOR_COLOR_ROW_ALT
    );

    new const Float:rowTop[10] =
    {
        121.0, 144.0, 167.0, 190.0, 213.0,
        236.0, 259.0, 282.0, 305.0, 328.0
    };

    s_CreatorTD[playerid][CreatorTD_GenderRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[0], 611.0, 2.15, CREATOR_COLOR_ROW);
    s_CreatorTD[playerid][CreatorTD_DayRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[1], 611.0, 2.15, CREATOR_COLOR_ROW_ALT);
    s_CreatorTD[playerid][CreatorTD_MonthRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[2], 611.0, 2.15, CREATOR_COLOR_ROW);
    s_CreatorTD[playerid][CreatorTD_YearRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[3], 611.0, 2.15, CREATOR_COLOR_ROW_ALT);
    s_CreatorTD[playerid][CreatorTD_ToneRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[4], 611.0, 2.15, CREATOR_COLOR_ROW);
    s_CreatorTD[playerid][CreatorTD_SkinRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[5], 611.0, 2.15, CREATOR_COLOR_ROW_ALT);
    s_CreatorTD[playerid][CreatorTD_VoiceRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[6], 611.0, 2.15, CREATOR_COLOR_ROW);
    s_CreatorTD[playerid][CreatorTD_HeightRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[7], 611.0, 2.15, CREATOR_COLOR_ROW_ALT);
    s_CreatorTD[playerid][CreatorTD_WeightRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[8], 611.0, 2.15, CREATOR_COLOR_ROW);
    s_CreatorTD[playerid][CreatorTD_BirthPlaceRow] =
        Creator_CreateBox(playerid, 403.0, rowTop[9], 611.0, 2.15, CREATOR_COLOR_ROW_ALT);

    // =========================================================
    // HEADER
    // =========================================================

    // Logo
    s_CreatorTD[playerid][CreatorTD_Title] = Creator_CreateText(playerid, 507.0, 43.0, "LOS SANTOS ROLEPLAY", CREATOR_COLOR_LIGHT, 0.30, 1.30);
    PlayerTextDrawFont(playerid, s_CreatorTD[playerid][CreatorTD_Title], TEXT_DRAW_FONT_3);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Title], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawBackgroundColor(playerid, s_CreatorTD[playerid][CreatorTD_Title], 0x000000FF);
    PlayerTextDrawSetOutline(playerid, s_CreatorTD[playerid][CreatorTD_Title], 2);

    // Khởi tạo nhân vật - sát hơn
    s_CreatorTD[playerid][CreatorTD_Subtitle] = Creator_CreateText(playerid, 507.0, 63.0, "CREATE CHARACTER", CREATOR_COLOR_ACCENT, 0.20, 0.95);
    PlayerTextDrawFont(playerid, s_CreatorTD[playerid][CreatorTD_Subtitle], TEXT_DRAW_FONT_3);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Subtitle], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawSetOutline(playerid, s_CreatorTD[playerid][CreatorTD_Subtitle], 1);

    // Tên nhân vật - sát hơn
    s_CreatorTD[playerid][CreatorTD_Name] = Creator_CreateText(playerid, 507.0, 99.0, "Nhan vat: Test Character", CREATOR_COLOR_WHITE, 0.19, 0.90);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Name], TEXT_DRAW_ALIGN_CENTER);

    // =========================================================
    // CAC DONG THONG TIN - SAT HON
    // =========================================================

    // Bắt đầu từ y = 117, mỗi dòng cách nhau 22
    s_CreatorTD[playerid][CreatorTD_GenderLabel]      = Creator_CreateText(playerid, 413.0, 126.0, "Gioi tinh:",   CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_GenderLeft]       = Creator_CreateArrow(playerid, 535.0, 125.0, "<");
    s_CreatorTD[playerid][CreatorTD_GenderValue]      = Creator_CreateValue(playerid, 568.0, 126.0, "Nam");
    s_CreatorTD[playerid][CreatorTD_GenderRight]      = Creator_CreateArrow(playerid, 601.0, 125.0, ">");

    s_CreatorTD[playerid][CreatorTD_DayLabel]         = Creator_CreateText(playerid, 413.0, 149.0, "Ngay sinh:",   CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_DayLeft]          = Creator_CreateArrow(playerid, 535.0, 148.0, "<");
    s_CreatorTD[playerid][CreatorTD_DayValue]         = Creator_CreateValue(playerid, 568.0, 149.0, "01");
    s_CreatorTD[playerid][CreatorTD_DayRight]         = Creator_CreateArrow(playerid, 601.0, 148.0, ">");

    s_CreatorTD[playerid][CreatorTD_MonthLabel]       = Creator_CreateText(playerid, 413.0, 172.0, "Thang sinh:",  CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_MonthLeft]        = Creator_CreateArrow(playerid, 535.0, 171.0, "<");
    s_CreatorTD[playerid][CreatorTD_MonthValue]       = Creator_CreateValue(playerid, 568.0, 172.0, "01");
    s_CreatorTD[playerid][CreatorTD_MonthRight]       = Creator_CreateArrow(playerid, 601.0, 171.0, ">");

    s_CreatorTD[playerid][CreatorTD_YearLabel]        = Creator_CreateText(playerid, 413.0, 195.0, "Nam sinh:",    CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_YearLeft]         = Creator_CreateArrow(playerid, 535.0, 194.0, "<");
    s_CreatorTD[playerid][CreatorTD_YearValue]        = Creator_CreateValue(playerid, 568.0, 195.0, "1964 (28 tuoi)", 0.16);
    s_CreatorTD[playerid][CreatorTD_YearRight]        = Creator_CreateArrow(playerid, 601.0, 194.0, ">");

    s_CreatorTD[playerid][CreatorTD_ToneLabel]        = Creator_CreateText(playerid, 413.0, 218.0, "Mau da:",      CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_ToneLeft]         = Creator_CreateArrow(playerid, 535.0, 217.0, "<");
    s_CreatorTD[playerid][CreatorTD_ToneValue]        = Creator_CreateValue(playerid, 568.0, 218.0, "Toi");
    s_CreatorTD[playerid][CreatorTD_ToneRight]        = Creator_CreateArrow(playerid, 601.0, 217.0, ">");

    s_CreatorTD[playerid][CreatorTD_SkinLabel]        = Creator_CreateText(playerid, 413.0, 241.0, "Ngoai hinh:",  CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_SkinLeft]         = Creator_CreateArrow(playerid, 535.0, 240.0, "<");
    s_CreatorTD[playerid][CreatorTD_SkinValue]        = Creator_CreateValue(playerid, 568.0, 241.0, "26 (1/6)", 0.17);
    s_CreatorTD[playerid][CreatorTD_SkinRight]        = Creator_CreateArrow(playerid, 601.0, 240.0, ">");

    s_CreatorTD[playerid][CreatorTD_VoiceLabel]       = Creator_CreateText(playerid, 413.0, 264.0, "Giong noi:",   CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_VoiceLeft]        = Creator_CreateArrow(playerid, 535.0, 263.0, "<");
    s_CreatorTD[playerid][CreatorTD_VoiceValue]       = Creator_CreateValue(playerid, 568.0, 264.0, "Tram");
    s_CreatorTD[playerid][CreatorTD_VoiceRight]       = Creator_CreateArrow(playerid, 601.0, 263.0, ">");

    s_CreatorTD[playerid][CreatorTD_HeightLabel]      = Creator_CreateText(playerid, 413.0, 287.0, "Chieu cao:",   CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_HeightLeft]       = Creator_CreateArrow(playerid, 535.0, 286.0, "<");
    s_CreatorTD[playerid][CreatorTD_HeightValue]      = Creator_CreateValue(playerid, 568.0, 287.0, "175 cm");
    s_CreatorTD[playerid][CreatorTD_HeightRight]      = Creator_CreateArrow(playerid, 601.0, 286.0, ">");

    s_CreatorTD[playerid][CreatorTD_WeightLabel]      = Creator_CreateText(playerid, 413.0, 310.0, "Can nang:",    CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_WeightLeft]       = Creator_CreateArrow(playerid, 535.0, 309.0, "<");
    s_CreatorTD[playerid][CreatorTD_WeightValue]      = Creator_CreateValue(playerid, 568.0, 310.0, "70 kg");
    s_CreatorTD[playerid][CreatorTD_WeightRight]      = Creator_CreateArrow(playerid, 601.0, 309.0, ">");

    s_CreatorTD[playerid][CreatorTD_BirthPlaceLabel]  = Creator_CreateText(playerid, 413.0, 333.0, "Noi sinh:",    CREATOR_COLOR_WHITE, 0.19, 0.90);
    s_CreatorTD[playerid][CreatorTD_BirthPlaceLeft]   = Creator_CreateArrow(playerid, 535.0, 332.0, "<");
    s_CreatorTD[playerid][CreatorTD_BirthPlaceValue]  = Creator_CreateValue(playerid, 568.0, 333.0, "Los Santos", 0.17);
    s_CreatorTD[playerid][CreatorTD_BirthPlaceRight]  = Creator_CreateArrow(playerid, 601.0, 332.0, ">");

    // Credit nho hon
    s_CreatorTD[playerid][CreatorTD_Hint] = Creator_CreateText(playerid, 507.0, 349.0, "USE ARROWS TO EDIT YOUR PROFILE", CREATOR_COLOR_GREY, 0.13, 0.70);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Hint], TEXT_DRAW_ALIGN_CENTER);

    // Nút xác nhận nhỏ gọn hơn
    s_CreatorTD[playerid][CreatorTD_Confirm] = Creator_CreateText(playerid, 507.0, 372.0, "XAC NHAN NHAN VAT", CREATOR_COLOR_LIGHT, 0.22, 1.05);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawUseBox(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], true);
    PlayerTextDrawBoxColor(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], CREATOR_COLOR_ACCENT);
    PlayerTextDrawTextSize(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], 12.0, 205.0);
    PlayerTextDrawSetSelectable(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], true);

    s_CreatorUIReady[playerid] = true;
    return 1;
}

//-----------------------------------------------------------------------------
// Refresh text
//-----------------------------------------------------------------------------

Creator_RefreshUI(playerid)
{
    if (!s_CreatorUIReady[playerid])
    {
        return 0;
    }

    new text[96];

    format(
        text,
        sizeof(text),
        "Nhan vat: %s",
        s_CharacterName[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_Name],
        text
    );

    if (s_CharacterGender[playerid] == 0)
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_GenderValue],
            "Nam"
        );
    }
    else
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_GenderValue],
            "Nu"
        );
    }

    format(
        text,
        sizeof(text),
        "%02d",
        s_CharacterBirthDay[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_DayValue],
        text
    );

    format(
        text,
        sizeof(text),
        "%02d",
        s_CharacterBirthMonth[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_MonthValue],
        text
    );

    format(
        text,
        sizeof(text),
        "%d (%d tuoi)",
        s_CharacterBirthYear[playerid],
        GetPlayerCharacterAge(playerid)
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_YearValue],
        text
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_ToneValue],
        g_SkinToneNames[s_CharacterSkinTone[playerid]]
    );

    format(
        text,
        sizeof(text),
        "%d (%d/%d)",
        s_CharacterSkin[playerid],
        s_CreatorSkinIndex[playerid] + 1,
        CREATOR_SKINS_PER_GROUP
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_SkinValue],
        text
    );

    if (s_CharacterGender[playerid] == 0)
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_VoiceValue],
            g_MaleVoiceNames[s_CharacterVoice[playerid]]
        );
    }
    else
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_VoiceValue],
            g_FemaleVoiceNames[s_CharacterVoice[playerid]]
        );
    }

    format(
        text,
        sizeof(text),
        "%d cm",
        s_CharacterHeight[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_HeightValue],
        text
    );

    format(
        text,
        sizeof(text),
        "%d kg",
        s_CharacterWeight[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_WeightValue],
        text
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_BirthPlaceValue],
        g_BirthPlaceNames[s_CharacterBirthPlace[playerid]]
    );

    return 1;
}

//-----------------------------------------------------------------------------
// UI show/hide
//-----------------------------------------------------------------------------

Creator_ShowUI(playerid)
{
    Creator_CreateUI(playerid);
    Creator_RefreshUI(playerid);

    SelectTextDraw(
        playerid,
        CREATOR_COLOR_HOVER
    );

    for (new i = 0; i < CreatorTD_Count; i++)
    {
        PlayerTextDrawShow(
            playerid,
            s_CreatorTD[playerid][i]
        );
    }

    return 1;
}

Creator_DestroyUI(playerid)
{
    if (!s_CreatorUIReady[playerid])
    {
        return 1;
    }

    for (new i = 0; i < CreatorTD_Count; i++)
    {
        PlayerTextDrawDestroy(
            playerid,
            s_CreatorTD[playerid][i]
        );

        s_CreatorTD[playerid][i] =
            PlayerText:INVALID_TEXT_DRAW;
    }

    s_CreatorUIReady[playerid] = false;
    return 1;
}

//-----------------------------------------------------------------------------
// World / Camera
//-----------------------------------------------------------------------------

CharacterCreator_ApplyWorld(playerid)
{
    SetPlayerInterior(
        playerid,
        CREATOR_INTERIOR
    );

    SetPlayerVirtualWorld(
        playerid,
        CREATOR_WORLD_BASE + playerid
    );

    SetPlayerPos(
        playerid,
        CREATOR_POS_X,
        CREATOR_POS_Y,
        CREATOR_POS_Z
    );

    SetPlayerFacingAngle(
        playerid,
        CREATOR_POS_A
    );

    SetPlayerSkin(
        playerid,
        s_CharacterSkin[playerid]
    );

    ResetPlayerWeapons(playerid);

    TogglePlayerControllable(
        playerid,
        false
    );

    SetPlayerCameraPos(
        playerid,
        CREATOR_CAMERA_X,
        CREATOR_CAMERA_Y,
        CREATOR_CAMERA_Z
    );

    SetPlayerCameraLookAt(
        playerid,
        CREATOR_CAMERA_LOOK_X,
        CREATOR_CAMERA_LOOK_Y,
        CREATOR_CAMERA_LOOK_Z,
        CAMERA_CUT
    );

    if (!UI_Show(playerid, UI_CREATOR))
        Creator_ShowUI(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Start creator
//-----------------------------------------------------------------------------

stock bool:CharacterCreator_IsActive(playerid)
{
    return s_CreatorActive[playerid];
}

CharacterCreator_Start(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    Creator_NormalizeProfile(playerid);

    if (!Character_SetPlayerICName(playerid))
    {
        Kick(playerid);
        return 0;
    }

    s_CreatorActive[playerid] = true;
    s_CreatorSaving[playerid] = false;
    UI_Notify(playerid, "info", "Đã tạo nhân vật. Hãy hoàn tất hồ sơ của bạn.");

    SetSpawnInfo(
        playerid,
        NO_TEAM,
        s_CharacterSkin[playerid],
        CREATOR_POS_X,
        CREATOR_POS_Y,
        CREATOR_POS_Z,
        CREATOR_POS_A
    );

    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        TogglePlayerSpectating(
            playerid,
            false
        );
    }
    else
    {
        SpawnPlayer(playerid);
    }

    // CEF uses a single submit flow: save the normalized profile immediately
    // after the newly created character has loaded.
    if (UI_UseCEF(playerid))
        CharacterCreator_Confirm(playerid);

    return 1;
}

//-----------------------------------------------------------------------------
// Save profile
//-----------------------------------------------------------------------------

CharacterCreator_Confirm(playerid)
{
    if (!s_CreatorActive[playerid] ||
        s_CreatorSaving[playerid])
    {
        return 0;
    }

    s_CreatorSaving[playerid] = true;

    UI_Notify(playerid, "info", "Đang lưu hồ sơ nhân vật...");
    printf("[GTASA UI] creator save begin player=%d character=%d account=%d", playerid, s_CharacterID[playerid], GetPlayerAccountID(playerid));

    CancelSelectTextDraw(playerid);

    new query[1024];

    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_characters` SET `character_created`=1,`gender`=%d,`birth_day`=%d,`birth_month`=%d,`birth_year`=%d,`skin_tone`=%d,`skin`=%d,`voice`=%d,`height_cm`=%d,`weight_kg`=%d,`birth_place`=%d WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;",
        s_CharacterGender[playerid],
        s_CharacterBirthDay[playerid],
        s_CharacterBirthMonth[playerid],
        s_CharacterBirthYear[playerid],
        s_CharacterSkinTone[playerid],
        s_CharacterSkin[playerid],
        s_CharacterVoice[playerid],
        s_CharacterHeight[playerid],
        s_CharacterWeight[playerid],
        s_CharacterBirthPlace[playerid],
        s_CharacterID[playerid],
        GetPlayerAccountID(playerid)
    );

    mysql_tquery(
        g_DatabaseHandle,
        query,
        "OnCharacterCreatorSaved",
        "d",
        playerid
    );

    printf("[GTASA UI] creator save query queued player=%d", playerid);

    return 1;
}

public OnCharacterCreatorSaved(playerid)
{
    printf("[GTASA UI] creator save callback player=%d connected=%d loaded=%d", playerid, IsPlayerConnected(playerid), IsPlayerCharacterLoaded(playerid));
    s_CreatorSaving[playerid] = false;
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid))
    {
        return 1;
    }

    s_CharacterCreated[playerid] = 1;
    s_CreatorActive[playerid] = false;
    UI_Close(playerid);

    UI_Notify(playerid, "success", "Đã tạo nhân vật thành công.");
    
    Creator_DestroyUI(playerid);
    
    TogglePlayerControllable(playerid, false);
    
    SendClientMessage(playerid, COLOR_WHITE, "Ho so nhan vat da duoc khoi tao thanh cong.");
    
    Cinematic_StartNewCharacter(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Clicks
//-----------------------------------------------------------------------------

hook OnPlayerClickPlayerTextDraw( playerid, PlayerText:playertextid)
{
    if (!s_CreatorActive[playerid] ||
        s_CreatorSaving[playerid])
    {
        return 0;
    }

    // Gender
    if (playertextid == s_CreatorTD[playerid][CreatorTD_GenderLeft] ||
        playertextid == s_CreatorTD[playerid][CreatorTD_GenderRight])
    {
        s_CharacterGender[playerid] =
            Creator_Wrap(
                s_CharacterGender[playerid],
                0,
                1,
                1
            );

        s_CreatorSkinIndex[playerid] = 0;

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);

        return 1;
    }

    // Day -
    if (playertextid == s_CreatorTD[playerid][CreatorTD_DayLeft])
    {
        new const maxDay =
            Creator_GetDaysInMonth(
                s_CharacterBirthMonth[playerid],
                s_CharacterBirthYear[playerid]
            );

        s_CharacterBirthDay[playerid] =
            Creator_Wrap(
                s_CharacterBirthDay[playerid],
                1,
                maxDay,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Day +
    if (playertextid == s_CreatorTD[playerid][CreatorTD_DayRight])
    {
        new const maxDay =
            Creator_GetDaysInMonth(
                s_CharacterBirthMonth[playerid],
                s_CharacterBirthYear[playerid]
            );

        s_CharacterBirthDay[playerid] =
            Creator_Wrap(
                s_CharacterBirthDay[playerid],
                1,
                maxDay,
                1);

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Month
    if (playertextid == s_CreatorTD[playerid][CreatorTD_MonthLeft])
    {
        s_CharacterBirthMonth[playerid] =
            Creator_Wrap(
                s_CharacterBirthMonth[playerid],
                1,
                12,
                -1);

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_MonthRight])
    {
        s_CharacterBirthMonth[playerid] =
            Creator_Wrap(
                s_CharacterBirthMonth[playerid],
                1,
                12,
                1 );

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Year
    if (playertextid == s_CreatorTD[playerid][CreatorTD_YearLeft])
    {
        s_CharacterBirthYear[playerid] =
            Creator_Wrap(
                s_CharacterBirthYear[playerid],
                CHARACTER_MIN_BIRTH_YEAR,
                CHARACTER_MAX_BIRTH_YEAR,
                -1);

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_YearRight])
    {
        s_CharacterBirthYear[playerid] =
            Creator_Wrap(
                s_CharacterBirthYear[playerid],
                CHARACTER_MIN_BIRTH_YEAR,
                CHARACTER_MAX_BIRTH_YEAR,
                1
            );

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Skin tone
    if (playertextid == s_CreatorTD[playerid][CreatorTD_ToneLeft])
    {
        s_CharacterSkinTone[playerid] =
            Creator_Wrap(
                s_CharacterSkinTone[playerid],
                0,
                2,
                -1
            );

        s_CreatorSkinIndex[playerid] = 0;

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_ToneRight])
    {
        s_CharacterSkinTone[playerid] =
            Creator_Wrap(
                s_CharacterSkinTone[playerid],
                0,
                2,
                1
            );

        s_CreatorSkinIndex[playerid] = 0;

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Skin
    if (playertextid == s_CreatorTD[playerid][CreatorTD_SkinLeft])
    {
        s_CreatorSkinIndex[playerid] =
            Creator_Wrap(
                s_CreatorSkinIndex[playerid],
                0,
                CREATOR_SKINS_PER_GROUP - 1,
                -1
            );

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_SkinRight])
    {
        s_CreatorSkinIndex[playerid] =
            Creator_Wrap(
                s_CreatorSkinIndex[playerid],
                0,
                CREATOR_SKINS_PER_GROUP - 1,
                1
            );

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Voice
    if (playertextid == s_CreatorTD[playerid][CreatorTD_VoiceLeft])
    {
        s_CharacterVoice[playerid] =
            Creator_Wrap(
                s_CharacterVoice[playerid],
                0,
                3,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_VoiceRight])
    {
        s_CharacterVoice[playerid] =
            Creator_Wrap(
                s_CharacterVoice[playerid],
                0,
                3,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Height
    if (playertextid == s_CreatorTD[playerid][CreatorTD_HeightLeft])
    {
        s_CharacterHeight[playerid] =
            Creator_Wrap(
                s_CharacterHeight[playerid],
                150,
                210,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_HeightRight])
    {
        s_CharacterHeight[playerid] =
            Creator_Wrap(
                s_CharacterHeight[playerid],
                150,
                210,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Weight
    if (playertextid == s_CreatorTD[playerid][CreatorTD_WeightLeft])
    {
        s_CharacterWeight[playerid] =
            Creator_Wrap(
                s_CharacterWeight[playerid],
                45,
                150,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_WeightRight])
    {
        s_CharacterWeight[playerid] =
            Creator_Wrap(
                s_CharacterWeight[playerid],
                45,
                150,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Birth place
    if (playertextid == s_CreatorTD[playerid][CreatorTD_BirthPlaceLeft])
    {
        s_CharacterBirthPlace[playerid] =
            Creator_Wrap(
                s_CharacterBirthPlace[playerid],
                0,
                3,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_BirthPlaceRight])
    {
        s_CharacterBirthPlace[playerid] =
            Creator_Wrap(
                s_CharacterBirthPlace[playerid],
                0,
                3,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Confirm
    if (playertextid == s_CreatorTD[playerid][CreatorTD_Confirm])
    {
        CharacterCreator_Confirm(playerid);
        return 1;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Connection cleanup
//-----------------------------------------------------------------------------

hook OnPlayerConnect(playerid)
{
    s_CreatorActive[playerid] = false;
    s_CreatorUIReady[playerid] = false;
    s_CreatorSaving[playerid] = false;
    s_CreatorSkinIndex[playerid] = 0;

    for (new i = 0; i < CreatorTD_Count; i++)
    {
        s_CreatorTD[playerid][i] =
            PlayerText:INVALID_TEXT_DRAW;
    }

    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    Creator_DestroyUI(playerid);

    s_CreatorActive[playerid] = false;
    s_CreatorSaving[playerid] = false;

    return 1;
}
Creator_SetCentered(playerid, PlayerText:td)
{
    PlayerTextDrawAlignment(playerid, td, TEXT_DRAW_ALIGN_CENTER);
    return 1;
}
