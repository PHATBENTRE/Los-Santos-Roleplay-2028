//-----------------------------------------------------------------------------
// Car restoration job - constants, contracts and runtime data
//-----------------------------------------------------------------------------

#define RESTORE_DIALOG_APPLICATION          (9100)
#define RESTORE_DIALOG_EMPLOYEE_MENU        (9101)
#define RESTORE_DIALOG_PROFILE              (9102)
#define RESTORE_DIALOG_GUIDE                (9103)
#define RESTORE_DIALOG_CONTRACTS            (9104)
#define RESTORE_DIALOG_CANCEL               (9105)
#define RESTORE_DIALOG_RESIGN               (9106)

#define RESTORE_MAX_OFFERS                  (3)
#define RESTORE_SKILL_STEPS                 (3)
#define RESTORE_SKILL_TIMEOUT_MS            (6500)

#define RESTORE_DAILY_SALARY                (450)
#define RESTORE_DAILY_ALLOWANCE             (150)

#define RESTORE_INTERACT_RANGE              (2.8)
#define RESTORE_VEHICLE_INTERACT_RANGE      (4.5)
#define RESTORE_DELIVERY_RANGE              (6.0)
#define RESTORE_BAY_CLEARANCE               (4.0)

#define RESTORE_RECRUITER_SKIN              (50)
#define RESTORE_STAGE_NONE                  (-1)

#define RESTORE_NPC_X                       (1039.6500)
#define RESTORE_NPC_Y                       (-1029.2500)
#define RESTORE_NPC_Z                       (32.1000)
#define RESTORE_NPC_A                       (90.0000)

enum _:E_RESTORE_DIFFICULTY
{
    RESTORE_DIFFICULTY_EASY = 1,
    RESTORE_DIFFICULTY_STANDARD,
    RESTORE_DIFFICULTY_ADVANCED
};

enum _:E_RESTORE_STAGE
{
    RESTORE_STAGE_INSPECTION = 0,
    RESTORE_STAGE_TIRES,
    RESTORE_STAGE_ENGINE,
    RESTORE_STAGE_BODY,
    RESTORE_STAGE_ELECTRICAL,
    RESTORE_STAGE_TEST_DRIVE
};

enum E_RESTORE_MODEL
{
    RESTORE_MODEL_ID,
    RESTORE_MODEL_DIFFICULTY,
    RESTORE_MODEL_REQUIRED_LEVEL,
    RESTORE_MODEL_COLOR_1,
    RESTORE_MODEL_COLOR_2,
    RESTORE_MODEL_NAME[24]
};

new const g_RestoreModels[][E_RESTORE_MODEL] =
{
    {401, RESTORE_DIFFICULTY_EASY,     1,  1,  1, "Bravura"},
    {410, RESTORE_DIFFICULTY_EASY,     1,  6,  6, "Manana"},
    {436, RESTORE_DIFFICULTY_EASY,     1,  3,  3, "Previon"},
    {439, RESTORE_DIFFICULTY_EASY,     1,  4,  4, "Stallion"},
    {405, RESTORE_DIFFICULTY_STANDARD, 1, 36, 36, "Sentinel"},
    {426, RESTORE_DIFFICULTY_STANDARD, 1, 53, 53, "Premier"},
    {445, RESTORE_DIFFICULTY_STANDARD, 1, 39, 39, "Admiral"},
    {458, RESTORE_DIFFICULTY_STANDARD, 1, 13, 13, "Solair"},
    {409, RESTORE_DIFFICULTY_ADVANCED, 3,  1,  1, "Stretch"},
    {415, RESTORE_DIFFICULTY_ADVANCED, 3, 73,  1, "Cheetah"},
    {429, RESTORE_DIFFICULTY_ADVANCED, 3, 12, 12, "Banshee"},
    {541, RESTORE_DIFFICULTY_ADVANCED, 3, 51,  1, "Bullet"}
};

new const Float:g_RestoreWorkBays[][4] =
{
    {1023.2000, -1023.8000, 31.6500, 0.0000},
    {1017.8000, -1023.8000, 31.6500, 0.0000},
    {1012.4000, -1023.8000, 31.6500, 0.0000},
    {1023.2000, -1015.0000, 31.6500, 180.0000},
    {1017.8000, -1015.0000, 31.6500, 180.0000},
    {1012.4000, -1015.0000, 31.6500, 180.0000}
};

enum E_RESTORE_DELIVERY_POINT
{
    Float:RESTORE_DELIVERY_X,
    Float:RESTORE_DELIVERY_Y,
    Float:RESTORE_DELIVERY_Z,
    RESTORE_DELIVERY_NAME[28]
};

new const g_RestoreDeliveryPoints[][E_RESTORE_DELIVERY_POINT] =
{
    {1642.4000, -1892.4000, 13.5500, "Unity Station"},
    {2131.9000, -1150.2000, 24.0000, "Jefferson"},
    {557.0000,  -1291.6000, 17.2000, "Market"},
    {2420.0000, -1222.0000, 25.3000, "East Los Santos"},
    {1089.0000, -923.8000,  43.4000, "Vinewood"}
};

new
    g_RestoreRecruiterActor = INVALID_ACTOR_ID,
    g_RestoreRecruiterPickup = -1,
    Text3D:g_RestoreRecruiterLabel = Text3D:INVALID_3DTEXT_ID;

new
    s_RestoreOfferModel[MAX_PLAYERS][RESTORE_MAX_OFFERS],
    s_RestoreOfferDelivery[MAX_PLAYERS][RESTORE_MAX_OFFERS],

    s_RestoreContractModel[MAX_PLAYERS],
    s_RestoreContractDelivery[MAX_PLAYERS],
    s_RestoreContractDifficulty[MAX_PLAYERS],
    s_RestoreContractStage[MAX_PLAYERS],
    s_RestoreLastModel[MAX_PLAYERS],

    s_RestoreVehicle[MAX_PLAYERS],
    s_RestoreVehicleToken[MAX_PLAYERS],
    s_RestoreVehicleBay[MAX_PLAYERS],
    Text3D:s_RestoreVehicleLabel[MAX_PLAYERS],

    bool:s_RestoreSkillActive[MAX_PLAYERS],
    s_RestoreSkillProgress[MAX_PLAYERS],
    KEY:s_RestoreExpectedKey[MAX_PLAYERS],
    s_RestoreSkillTimer[MAX_PLAYERS],
    s_RestoreSkillToken[MAX_PLAYERS];

new
    s_RestoreManagedOwner[MAX_VEHICLES],
    s_RestoreManagedToken[MAX_VEHICLES];

stock Restore_GetDifficultyName(difficulty, destination[], size)
{
    switch (difficulty)
    {
        case RESTORE_DIFFICULTY_EASY:
            format(destination, size, "Co ban");
        case RESTORE_DIFFICULTY_STANDARD:
            format(destination, size, "Tieu chuan");
        default:
            format(destination, size, "Cao cap");
    }
    return 1;
}

stock Restore_GetStageName(stage, destination[], size)
{
    switch (stage)
    {
        case RESTORE_STAGE_INSPECTION:
            format(destination, size, "Kiem tra tong quat");
        case RESTORE_STAGE_TIRES:
            format(destination, size, "Thay lop va can chinh banh");
        case RESTORE_STAGE_ENGINE:
            format(destination, size, "Phuc hoi dong co");
        case RESTORE_STAGE_BODY:
            format(destination, size, "Sua than vo va cua xe");
        case RESTORE_STAGE_ELECTRICAL:
            format(destination, size, "Sua dien va den xe");
        case RESTORE_STAGE_TEST_DRIVE:
            format(destination, size, "Chay thu va ban giao");
        default:
            format(destination, size, "Chua co hop dong");
    }
    return 1;
}

stock Restore_GetFinalPay(difficulty)
{
    switch (difficulty)
    {
        case RESTORE_DIFFICULTY_EASY: return 180;
        case RESTORE_DIFFICULTY_STANDARD: return 240;
        case RESTORE_DIFFICULTY_ADVANCED: return 320;
    }
    return 0;
}

stock Restore_GetFinalExperience(difficulty)
{
    switch (difficulty)
    {
        case RESTORE_DIFFICULTY_EASY: return 18;
        case RESTORE_DIFFICULTY_STANDARD: return 25;
        case RESTORE_DIFFICULTY_ADVANCED: return 32;
    }
    return 0;
}

stock Restore_GetPartPay(difficulty)
{
    return 35 + (difficulty * 15);
}

stock Restore_GetPartExperience(difficulty)
{
    return 6 + (difficulty * 2);
}

stock bool:Restore_IsEmployee(playerid)
{
    return pJobLoaded[playerid] &&
        pJob[playerid] == JOB_CAR_RESTORATION;
}

stock bool:Restore_IsVehicleIndexValid(vehicleid)
{
    return vehicleid > 0 && vehicleid < MAX_VEHICLES;
}

stock bool:Restore_HasContractVehicle(playerid)
{
    new const vehicleid = s_RestoreVehicle[playerid];

    return Restore_IsVehicleIndexValid(vehicleid) &&
        IsValidVehicle(vehicleid) &&
        s_RestoreManagedOwner[vehicleid] == playerid &&
        s_RestoreManagedToken[vehicleid] ==
            s_RestoreVehicleToken[playerid];
}

stock Restore_GetContractVehicle(playerid)
{
    if (!Restore_HasContractVehicle(playerid))
    {
        return INVALID_VEHICLE_ID;
    }
    return s_RestoreVehicle[playerid];
}

stock bool:Restore_IsOnContract(playerid)
{
    return Job_IsActive(playerid, JOB_CAR_RESTORATION) &&
        s_RestoreContractStage[playerid] != RESTORE_STAGE_NONE &&
        Restore_HasContractVehicle(playerid);
}

stock Float:Restore_Distance2D(
    Float:x1,
    Float:y1,
    Float:x2,
    Float:y2
)
{
    return floatsqroot(
        ((x1 - x2) * (x1 - x2)) +
        ((y1 - y2) * (y1 - y2))
    );
}

stock Restore_FindFreeBay()
{
    for (new bay = 0; bay < sizeof(g_RestoreWorkBays); bay++)
    {
        new bool:occupied = false;

        for (new vehicleid = 1; vehicleid < MAX_VEHICLES; vehicleid++)
        {
            if (!IsValidVehicle(vehicleid))
            {
                continue;
            }

            new Float:x, Float:y, Float:z;
            GetVehiclePos(vehicleid, x, y, z);

            if (Restore_Distance2D(
                    x,
                    y,
                    g_RestoreWorkBays[bay][0],
                    g_RestoreWorkBays[bay][1]
                ) <= RESTORE_BAY_CLEARANCE &&
                floatabs(z - g_RestoreWorkBays[bay][2]) <= 3.0)
            {
                occupied = true;
                break;
            }
        }

        if (!occupied)
        {
            return bay;
        }
    }
    return -1;
}

stock Restore_CancelSkill(playerid, bool:clearAnimation = true)
{
    if (s_RestoreSkillTimer[playerid])
    {
        KillTimer(s_RestoreSkillTimer[playerid]);
        s_RestoreSkillTimer[playerid] = 0;
    }

    s_RestoreSkillActive[playerid] = false;
    s_RestoreSkillProgress[playerid] = 0;
    s_RestoreExpectedKey[playerid] = KEY_NONE;
    s_RestoreSkillToken[playerid]++;

    if (clearAnimation && IsPlayerConnected(playerid))
    {
        ClearAnimations(playerid, SYNC_ALL);
    }
    return 1;
}

stock Restore_ResetContractState(playerid)
{
    Restore_CancelSkill(playerid, false);

    s_RestoreContractModel[playerid] = -1;
    s_RestoreContractDelivery[playerid] = -1;
    s_RestoreContractDifficulty[playerid] = 0;
    s_RestoreContractStage[playerid] = RESTORE_STAGE_NONE;

    s_RestoreVehicle[playerid] = INVALID_VEHICLE_ID;
    s_RestoreVehicleBay[playerid] = -1;
    s_RestoreVehicleLabel[playerid] = Text3D:INVALID_3DTEXT_ID;
    return 1;
}

stock Restore_InitializePlayer(playerid)
{
    for (new offer = 0; offer < RESTORE_MAX_OFFERS; offer++)
    {
        s_RestoreOfferModel[playerid][offer] = -1;
        s_RestoreOfferDelivery[playerid][offer] = -1;
    }

    s_RestoreLastModel[playerid] = -1;
    s_RestoreVehicleToken[playerid]++;
    Restore_ResetContractState(playerid);
    return 1;
}

stock Restore_ResetVehicleRegistry()
{
    for (new vehicleid = 0; vehicleid < MAX_VEHICLES; vehicleid++)
    {
        s_RestoreManagedOwner[vehicleid] = INVALID_PLAYER_ID;
        s_RestoreManagedToken[vehicleid] = 0;
    }
    return 1;
}
