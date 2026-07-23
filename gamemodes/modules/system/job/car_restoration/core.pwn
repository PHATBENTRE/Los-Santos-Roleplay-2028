//-----------------------------------------------------------------------------
// Car restoration job - world, contracts and repair gameplay
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

forward public Restore_SkillTimeout(
    playerid,
    skillToken,
    contractStage
);

stock Restore_CreateWorld()
{
    g_RestoreRecruiterActor = CreateActor(
        RESTORE_RECRUITER_SKIN,
        RESTORE_NPC_X,
        RESTORE_NPC_Y,
        RESTORE_NPC_Z,
        RESTORE_NPC_A
    );

    if (g_RestoreRecruiterActor != INVALID_ACTOR_ID)
    {
        SetActorInvulnerable(g_RestoreRecruiterActor, true);
        SetActorVirtualWorld(g_RestoreRecruiterActor, 0);
    }

    g_RestoreRecruiterPickup = CreatePickup(
        1239,
        1,
        RESTORE_NPC_X,
        RESTORE_NPC_Y,
        RESTORE_NPC_Z,
        0
    );

    g_RestoreRecruiterLabel = Create3DTextLabel(
        "{F5A623}LOS SANTOS RESTORATION\n\
{FFFFFF}Quan doc xuong xe\n\
{FFD54F}Nhan Y de tuong tac",
        COLOR_WHITE,
        RESTORE_NPC_X,
        RESTORE_NPC_Y,
        RESTORE_NPC_Z + 1.0,
        20.0,
        0,
        true
    );
    return 1;
}

stock Restore_DestroyWorld()
{
    if (IsValidActor(g_RestoreRecruiterActor))
    {
        DestroyActor(g_RestoreRecruiterActor);
    }
    if (IsValidPickup(g_RestoreRecruiterPickup))
    {
        DestroyPickup(g_RestoreRecruiterPickup);
    }
    if (IsValid3DTextLabel(g_RestoreRecruiterLabel))
    {
        Delete3DTextLabel(g_RestoreRecruiterLabel);
    }

    g_RestoreRecruiterActor = INVALID_ACTOR_ID;
    g_RestoreRecruiterPickup = -1;
    g_RestoreRecruiterLabel = Text3D:INVALID_3DTEXT_ID;
    return 1;
}

stock bool:Restore_IsOfferModelUsed(playerid, offerLimit, modelIndex)
{
    for (new offer = 0; offer < offerLimit; offer++)
    {
        if (s_RestoreOfferModel[playerid][offer] == modelIndex)
        {
            return true;
        }
    }
    return false;
}

stock Restore_GenerateOffers(playerid)
{
    new const jobLevel = Job_GetLevel(
        playerid,
        JOB_CAR_RESTORATION
    );

    for (new offer = 0; offer < RESTORE_MAX_OFFERS; offer++)
    {
        s_RestoreOfferModel[playerid][offer] = -1;
        s_RestoreOfferDelivery[playerid][offer] = -1;

        new modelIndex = -1;

        for (new attempt = 0; attempt < 48; attempt++)
        {
            new const candidate = random(sizeof(g_RestoreModels));

            if (g_RestoreModels[candidate][
                    RESTORE_MODEL_REQUIRED_LEVEL
                ] > jobLevel ||
                candidate == s_RestoreLastModel[playerid] ||
                Restore_IsOfferModelUsed(playerid, offer, candidate))
            {
                continue;
            }

            modelIndex = candidate;
            break;
        }

        if (modelIndex == -1)
        {
            for (new candidate = 0;
                candidate < sizeof(g_RestoreModels);
                candidate++)
            {
                if (g_RestoreModels[candidate][
                        RESTORE_MODEL_REQUIRED_LEVEL
                    ] <= jobLevel &&
                    !Restore_IsOfferModelUsed(
                        playerid,
                        offer,
                        candidate
                    ))
                {
                    modelIndex = candidate;
                    break;
                }
            }
        }

        if (modelIndex == -1)
        {
            return 0;
        }

        s_RestoreOfferModel[playerid][offer] = modelIndex;
        s_RestoreOfferDelivery[playerid][offer] =
            random(sizeof(g_RestoreDeliveryPoints));
    }
    return 1;
}

stock Restore_AcceptOffer(playerid, offer)
{
    if (!Restore_IsEmployee(playerid))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ban chua phai ky thuat vien cua xuong.",
            4000
        );
        return 0;
    }

    if (offer < 0 || offer >= RESTORE_MAX_OFFERS)
    {
        return 0;
    }

    if (Restore_IsOnContract(playerid))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ban dang co mot hop dong phuc che chua hoan tat.",
            4500
        );
        return 0;
    }

    if (Job_GetActive(playerid) != JOB_NONE)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ban dang trong mot ca lam viec khac.",
            4000
        );
        return 0;
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Hay xuong xe truoc khi nhan hop dong.",
            4000
        );
        return 0;
    }

    new const modelIndex =
        s_RestoreOfferModel[playerid][offer];
    new const deliveryPoint =
        s_RestoreOfferDelivery[playerid][offer];

    if (modelIndex < 0 ||
        modelIndex >= sizeof(g_RestoreModels) ||
        deliveryPoint < 0 ||
        deliveryPoint >= sizeof(g_RestoreDeliveryPoints))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Danh sach hop dong da het han. Hay mo lai.",
            4000
        );
        return 0;
    }

    if (Restore_HasContractVehicle(playerid) ||
        s_RestoreVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        Restore_DestroyContractVehicle(playerid);
    }

    new const bay = Restore_FindFreeBay();
    if (bay == -1)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Tat ca khoang sua xe dang ban. Hay thu lai sau.",
            5000
        );
        return 0;
    }

    if (!Job_Start(playerid, JOB_CAR_RESTORATION))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Khong the bat dau ca phuc che luc nay.",
            4500
        );
        return 0;
    }

    s_RestoreContractModel[playerid] = modelIndex;
    s_RestoreContractDelivery[playerid] = deliveryPoint;
    s_RestoreContractDifficulty[playerid] =
        g_RestoreModels[modelIndex][RESTORE_MODEL_DIFFICULTY];
    s_RestoreContractStage[playerid] =
        RESTORE_STAGE_INSPECTION;

    if (!Restore_CreateContractVehicle(playerid, modelIndex, bay))
    {
        Job_Stop(playerid, JOB_STOP_QUIT);
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Khong the dua xe hop dong vao xuong luc nay.",
            4500
        );
        return 0;
    }

    new message[192];
    format(
        message,
        sizeof(message),
        "Da nhan %s. Den khoang sua so %d, lai gan xe va nhan Y de kiem tra.",
        g_RestoreModels[modelIndex][RESTORE_MODEL_NAME],
        bay + 1
    );
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        message,
        6500
    );
    return 1;
}

stock Restore_GetSkillKeyName(
    KEY:key,
    destination[],
    size
)
{
    if (key == KEY_YES)
    {
        format(destination, size, "Y");
    }
    else if (key == KEY_NO)
    {
        format(destination, size, "N");
    }
    else
    {
        format(destination, size, "C");
    }
    return 1;
}

stock Restore_SetNextSkillKey(playerid)
{
    switch (random(3))
    {
        case 0: s_RestoreExpectedKey[playerid] = KEY_YES;
        case 1: s_RestoreExpectedKey[playerid] = KEY_NO;
        default: s_RestoreExpectedKey[playerid] = KEY_CROUCH;
    }

    new keyName[8], message[128];
    Restore_GetSkillKeyName(
        s_RestoreExpectedKey[playerid],
        keyName,
        sizeof(keyName)
    );

    format(
        message,
        sizeof(message),
        "Kiem tra ky nang %d/%d: nhan phim %s.",
        s_RestoreSkillProgress[playerid] + 1,
        RESTORE_SKILL_STEPS,
        keyName
    );
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_BASIC,
        message,
        RESTORE_SKILL_TIMEOUT_MS
    );

    if (s_RestoreSkillTimer[playerid])
    {
        KillTimer(s_RestoreSkillTimer[playerid]);
    }

    s_RestoreSkillToken[playerid]++;
    s_RestoreSkillTimer[playerid] = SetTimerEx(
        "Restore_SkillTimeout",
        RESTORE_SKILL_TIMEOUT_MS,
        false,
        "ddd",
        playerid,
        s_RestoreSkillToken[playerid],
        s_RestoreContractStage[playerid]
    );
    return 1;
}

stock Restore_BeginSkill(playerid)
{
    if (!Restore_IsOnContract(playerid) ||
        s_RestoreContractStage[playerid] < RESTORE_STAGE_INSPECTION ||
        s_RestoreContractStage[playerid] >=
            RESTORE_STAGE_TEST_DRIVE)
    {
        return 0;
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Hay xuong xe de thuc hien cong doan phuc che.",
            4000
        );
        return 0;
    }

    new const vehicleid = Restore_GetContractVehicle(playerid);
    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);

    if (!IsPlayerInRangeOfPoint(
            playerid,
            RESTORE_VEHICLE_INTERACT_RANGE,
            x,
            y,
            z
        ))
    {
        return 0;
    }

    if (s_RestoreSkillActive[playerid])
    {
        return 0;
    }

    if (s_RestoreContractStage[playerid] ==
        RESTORE_STAGE_ENGINE)
    {
        SetVehicleParamsEx(
            vehicleid,
            -1,
            -1,
            -1,
            -1,
            VEHICLE_PARAMS_ON,
            -1,
            -1
        );
    }

    s_RestoreSkillActive[playerid] = true;
    s_RestoreSkillProgress[playerid] = 0;

    ApplyAnimation(
        playerid,
        "CAR",
        "Fixn_Car_Loop",
        4.0,
        true,
        false,
        false,
        false,
        0,
        SYNC_ALL
    );
    Restore_SetNextSkillKey(playerid);
    return 1;
}

stock Restore_ShowCurrentStage(playerid)
{
    if (!Restore_IsOnContract(playerid))
    {
        return 0;
    }

    new stageName[40], message[192];
    Restore_GetStageName(
        s_RestoreContractStage[playerid],
        stageName,
        sizeof(stageName)
    );

    if (s_RestoreContractStage[playerid] ==
        RESTORE_STAGE_TEST_DRIVE)
    {
        new const delivery =
            s_RestoreContractDelivery[playerid];

        format(
            message,
            sizeof(message),
            "Cong doan: %s. Lai xe den %s va nhan Y tai diem ban giao.",
            stageName,
            g_RestoreDeliveryPoints[delivery][
                RESTORE_DELIVERY_NAME
            ]
        );
    }
    else
    {
        format(
            message,
            sizeof(message),
            "Cong doan: %s. Lai gan xe hop dong va nhan Y.",
            stageName
        );
    }

    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        message,
        6000
    );
    return 1;
}

stock Restore_CompleteRepairStage(playerid)
{
    if (!Restore_IsOnContract(playerid))
    {
        return 0;
    }

    new const completedStage =
        s_RestoreContractStage[playerid];

    if (completedStage < RESTORE_STAGE_INSPECTION ||
        completedStage >= RESTORE_STAGE_TEST_DRIVE)
    {
        return 0;
    }

    Restore_CancelSkill(playerid);
    Restore_ApplyCompletedStage(playerid, completedStage);

    new const difficulty =
        s_RestoreContractDifficulty[playerid];
    new const partPay = Restore_GetPartPay(difficulty);
    new const partExperience =
        Restore_GetPartExperience(difficulty);

    Job_RecordTask(
        playerid,
        partPay,
        partExperience,
        true
    );

    s_RestoreContractStage[playerid]++;

    new stageName[40], message[192];
    Restore_GetStageName(
        completedStage,
        stageName,
        sizeof(stageName)
    );
    format(
        message,
        sizeof(message),
        "Hoan tat %s +$%d. Chuyen sang cong doan tiep theo.",
        stageName,
        partPay
    );
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        message,
        5000
    );

    if (s_RestoreContractStage[playerid] ==
        RESTORE_STAGE_TEST_DRIVE)
    {
        new const delivery =
            s_RestoreContractDelivery[playerid];

        SetPlayerCheckpoint(
            playerid,
            g_RestoreDeliveryPoints[delivery][RESTORE_DELIVERY_X],
            g_RestoreDeliveryPoints[delivery][RESTORE_DELIVERY_Y],
            g_RestoreDeliveryPoints[delivery][RESTORE_DELIVERY_Z],
            4.0
        );
    }
    else
    {
        new const bay = s_RestoreVehicleBay[playerid];
        SetPlayerCheckpoint(
            playerid,
            g_RestoreWorkBays[bay][0],
            g_RestoreWorkBays[bay][1],
            g_RestoreWorkBays[bay][2],
            3.0
        );
    }

    Restore_ShowCurrentStage(playerid);
    return 1;
}

stock Restore_HandleSkillInput(
    playerid,
    KEY:newkeys,
    KEY:oldkeys
)
{
    if (!s_RestoreSkillActive[playerid])
    {
        return 0;
    }

    if (!Restore_IsOnContract(playerid) ||
        s_RestoreContractStage[playerid] >=
            RESTORE_STAGE_TEST_DRIVE)
    {
        Restore_CancelSkill(playerid);
        return 1;
    }

    new KEY:pressedKey = KEY_NONE;

    if ((newkeys & KEY_YES) && !(oldkeys & KEY_YES))
    {
        pressedKey = KEY_YES;
    }
    else if ((newkeys & KEY_NO) && !(oldkeys & KEY_NO))
    {
        pressedKey = KEY_NO;
    }
    else if ((newkeys & KEY_CROUCH) &&
        !(oldkeys & KEY_CROUCH))
    {
        pressedKey = KEY_CROUCH;
    }
    else
    {
        return 0;
    }

    new const vehicleid = Restore_GetContractVehicle(playerid);
    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);

    if (!IsPlayerInRangeOfPoint(
            playerid,
            RESTORE_VEHICLE_INTERACT_RANGE + 1.0,
            x,
            y,
            z
        ))
    {
        Restore_CancelSkill(playerid);
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Thao tac da huy vi ban roi khoi xe.",
            3500
        );
        return 1;
    }

    if (pressedKey != s_RestoreExpectedKey[playerid])
    {
        s_RestoreSkillProgress[playerid] = 0;
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Sai phim. Chuoi thao tac duoc bat dau lai, khong mat tien.",
            3500
        );
        Restore_SetNextSkillKey(playerid);
        return 1;
    }

    s_RestoreSkillProgress[playerid]++;

    if (s_RestoreSkillProgress[playerid] >=
        RESTORE_SKILL_STEPS)
    {
        return Restore_CompleteRepairStage(playerid);
    }

    Restore_SetNextSkillKey(playerid);
    return 1;
}

public Restore_SkillTimeout(
    playerid,
    skillToken,
    contractStage
)
{
    if (!IsPlayerConnected(playerid) ||
        !s_RestoreSkillActive[playerid] ||
        s_RestoreSkillToken[playerid] != skillToken ||
        s_RestoreContractStage[playerid] != contractStage)
    {
        return 1;
    }

    s_RestoreSkillTimer[playerid] = 0;
    Restore_CancelSkill(playerid);
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        "Het thoi gian thao tac. Nhan Y gan xe de thu lai.",
        4000
    );
    return 1;
}

stock Restore_CompleteContract(playerid)
{
    if (!Restore_IsOnContract(playerid) ||
        s_RestoreContractStage[playerid] !=
            RESTORE_STAGE_TEST_DRIVE)
    {
        return 0;
    }

    new const vehicleid = Restore_GetContractVehicle(playerid);
    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER ||
        GetPlayerVehicleID(playerid) != vehicleid)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ban phai lai chinh xe hop dong den diem ban giao.",
            4500
        );
        return 0;
    }

    new const delivery = s_RestoreContractDelivery[playerid];
    if (!IsPlayerInRangeOfPoint(
            playerid,
            RESTORE_DELIVERY_RANGE,
            g_RestoreDeliveryPoints[delivery][RESTORE_DELIVERY_X],
            g_RestoreDeliveryPoints[delivery][RESTORE_DELIVERY_Y],
            g_RestoreDeliveryPoints[delivery][RESTORE_DELIVERY_Z]
        ))
    {
        return 0;
    }

    new Float:vehicleHealth;
    GetVehicleHealth(vehicleid, vehicleHealth);

    new const difficulty =
        s_RestoreContractDifficulty[playerid];
    new finalPay = Restore_GetFinalPay(difficulty);
    new qualityPercent = 100;

    if (vehicleHealth < 700.0)
    {
        qualityPercent = 60;
    }
    else if (vehicleHealth < 850.0)
    {
        qualityPercent = 80;
    }

    finalPay = (finalPay * qualityPercent) / 100;

    new const modelIndex =
        s_RestoreContractModel[playerid];
    new modelName[24];
    format(
        modelName,
        sizeof(modelName),
        "%s",
        g_RestoreModels[modelIndex][RESTORE_MODEL_NAME]
    );

    s_RestoreLastModel[playerid] = modelIndex;

    Job_CompleteRun(
        playerid,
        finalPay,
        Restore_GetFinalExperience(difficulty)
    );
    Job_Stop(playerid, JOB_STOP_COMPLETE);

    new message[192];
    format(
        message,
        sizeof(message),
        "Da ban giao %s +$%d. Chat luong phuc che: %d%%.",
        modelName,
        finalPay,
        qualityPercent
    );
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        message,
        6500
    );
    return 1;
}

stock Restore_HandleRecruiterInteraction(playerid)
{
    if (!pJobLoaded[playerid])
    {
        Pizza_LoadCharacterJob(playerid);
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Dang tai ho so cong viec. Hay nhan Y lai sau giay lat.",
            4000
        );
        return 1;
    }

    if (Restore_IsEmployee(playerid))
    {
        Restore_ShowEmployeeMenu(playerid);
    }
    else
    {
        Restore_ShowApplication(playerid);
    }
    return 1;
}

stock Restore_HandleYInteraction(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    if (IsPlayerInRangeOfPoint(
            playerid,
            RESTORE_INTERACT_RANGE,
            RESTORE_NPC_X,
            RESTORE_NPC_Y,
            RESTORE_NPC_Z
        ))
    {
        return Restore_HandleRecruiterInteraction(playerid);
    }

    if (!Restore_IsOnContract(playerid))
    {
        return 0;
    }

    if (s_RestoreContractStage[playerid] ==
        RESTORE_STAGE_TEST_DRIVE)
    {
        return Restore_CompleteContract(playerid);
    }

    return Restore_BeginSkill(playerid);
}

hook OnGameModeInit()
{
    Restore_ResetVehicleRegistry();
    Job_Register(JOB_CAR_RESTORATION, "Phuc che xe");
    Restore_CreateWorld();
    return 1;
}

hook OnGameModeExit()
{
    Restore_DestroyWorld();
    return 1;
}

hook OnPlayerConnect(playerid)
{
    Restore_InitializePlayer(playerid);
    return 1;
}

hook OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
    if (s_RestoreSkillActive[playerid])
    {
        Restore_HandleSkillInput(
            playerid,
            newkeys,
            oldkeys
        );
        return 1;
    }

    if ((newkeys & KEY_YES) && !(oldkeys & KEY_YES))
    {
        Restore_HandleYInteraction(playerid);
    }
    return 1;
}
