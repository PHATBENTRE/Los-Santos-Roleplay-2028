//-----------------------------------------------------------------------------
// Car restoration job - contract vehicle lifecycle
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

stock Restore_DestroyContractVehicle(playerid)
{
    new const vehicleid = s_RestoreVehicle[playerid];
    new const vehicleToken = s_RestoreVehicleToken[playerid];

    Restore_CancelSkill(playerid);
    DisablePlayerCheckpoint(playerid);

    if (s_RestoreVehicleLabel[playerid] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(s_RestoreVehicleLabel[playerid]);
        s_RestoreVehicleLabel[playerid] = Text3D:INVALID_3DTEXT_ID;
    }

    if (IsPlayerConnected(playerid) &&
        Restore_IsVehicleIndexValid(vehicleid) &&
        IsPlayerInVehicle(playerid, vehicleid))
    {
        RemovePlayerFromVehicle(playerid);
    }

    if (Restore_IsVehicleIndexValid(vehicleid) &&
        s_RestoreManagedOwner[vehicleid] == playerid &&
        s_RestoreManagedToken[vehicleid] == vehicleToken)
    {
        s_RestoreManagedOwner[vehicleid] = INVALID_PLAYER_ID;
        s_RestoreManagedToken[vehicleid] = 0;
        s_RestoreVehicle[playerid] = INVALID_VEHICLE_ID;
        s_RestoreVehicleToken[playerid]++;

        if (IsValidVehicle(vehicleid))
        {
            DestroyVehicle(vehicleid);
        }
    }
    else
    {
        s_RestoreVehicle[playerid] = INVALID_VEHICLE_ID;
        s_RestoreVehicleToken[playerid]++;
    }

    Restore_ResetContractState(playerid);
    return 1;
}

stock Restore_CreateContractVehicle(playerid, modelIndex, bay)
{
    if (modelIndex < 0 ||
        modelIndex >= sizeof(g_RestoreModels) ||
        bay < 0 ||
        bay >= sizeof(g_RestoreWorkBays))
    {
        return 0;
    }

    if (Restore_HasContractVehicle(playerid) ||
        s_RestoreVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        Restore_DestroyContractVehicle(playerid);
    }

    s_RestoreVehicleToken[playerid]++;

    new const vehicleid = CreateVehicle(
        g_RestoreModels[modelIndex][RESTORE_MODEL_ID],
        g_RestoreWorkBays[bay][0],
        g_RestoreWorkBays[bay][1],
        g_RestoreWorkBays[bay][2],
        g_RestoreWorkBays[bay][3],
        g_RestoreModels[modelIndex][RESTORE_MODEL_COLOR_1],
        g_RestoreModels[modelIndex][RESTORE_MODEL_COLOR_2],
        -1
    );

    if (!Restore_IsVehicleIndexValid(vehicleid) ||
        !IsValidVehicle(vehicleid))
    {
        return 0;
    }

    s_RestoreVehicle[playerid] = vehicleid;
    s_RestoreVehicleBay[playerid] = bay;
    s_RestoreManagedOwner[vehicleid] = playerid;
    s_RestoreManagedToken[vehicleid] =
        s_RestoreVehicleToken[playerid];

    SetVehicleNumberPlate(vehicleid, "RESTORE");
    SetVehicleHealth(vehicleid, 450.0);
    UpdateVehicleDamageStatus(
        vehicleid,
        VEHICLE_PANEL_STATUS:0x11111111,
        VEHICLE_DOOR_STATUS:0x04040204,
        VEHICLE_LIGHT_STATUS:0x45,
        VEHICLE_TYRE_STATUS:0x0F
    );
    SetVehicleParamsEx(
        vehicleid,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_ON,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_ON
    );

    new labelText[144];
    format(
        labelText,
        sizeof(labelText),
        "{F5A623}XE DANG PHUC CHE\n{FFFFFF}%s\n{BDBDBD}Ky thuat vien: %s",
        g_RestoreModels[modelIndex][RESTORE_MODEL_NAME],
        s_CharacterName[playerid]
    );

    s_RestoreVehicleLabel[playerid] = Create3DTextLabel(
        labelText,
        COLOR_WHITE,
        0.0,
        0.0,
        0.0,
        25.0,
        0,
        true
    );
    Attach3DTextLabelToVehicle(
        s_RestoreVehicleLabel[playerid],
        vehicleid,
        0.0,
        0.0,
        1.1
    );

    SetPlayerCheckpoint(
        playerid,
        g_RestoreWorkBays[bay][0],
        g_RestoreWorkBays[bay][1],
        g_RestoreWorkBays[bay][2],
        3.0
    );
    return 1;
}

stock Restore_ApplyCompletedStage(playerid, completedStage)
{
    new const vehicleid = Restore_GetContractVehicle(playerid);
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        return 0;
    }

    new
        VEHICLE_PANEL_STATUS:panels,
        VEHICLE_DOOR_STATUS:doors,
        VEHICLE_LIGHT_STATUS:lights,
        VEHICLE_TYRE_STATUS:tyres;

    GetVehicleDamageStatus(
        vehicleid,
        panels,
        doors,
        lights,
        tyres
    );

    switch (completedStage)
    {
        case RESTORE_STAGE_INSPECTION:
        {
            SetVehicleHealth(vehicleid, 520.0);
        }
        case RESTORE_STAGE_TIRES:
        {
            tyres = VEHICLE_TYRE_STATUS_NONE;
            UpdateVehicleDamageStatus(
                vehicleid,
                panels,
                doors,
                lights,
                tyres
            );
        }
        case RESTORE_STAGE_ENGINE:
        {
            SetVehicleHealth(vehicleid, 820.0);
            SetVehicleParamsEx(
                vehicleid,
                VEHICLE_PARAMS_OFF,
                -1,
                -1,
                -1,
                VEHICLE_PARAMS_OFF,
                -1,
                -1
            );
        }
        case RESTORE_STAGE_BODY:
        {
            panels = VEHICLE_PANEL_STATUS_NONE;
            doors = VEHICLE_DOOR_STATUS_NONE;
            UpdateVehicleDamageStatus(
                vehicleid,
                panels,
                doors,
                lights,
                tyres
            );
        }
        case RESTORE_STAGE_ELECTRICAL:
        {
            RepairVehicle(vehicleid);
            SetVehicleHealth(vehicleid, 1000.0);
            SetVehicleParamsEx(
                vehicleid,
                VEHICLE_PARAMS_ON,
                VEHICLE_PARAMS_ON,
                VEHICLE_PARAMS_OFF,
                VEHICLE_PARAMS_OFF,
                VEHICLE_PARAMS_OFF,
                VEHICLE_PARAMS_OFF,
                VEHICLE_PARAMS_ON
            );
        }
    }
    return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    #pragma unused oldstate

    if (newstate != _:PLAYER_STATE_DRIVER &&
        newstate != _:PLAYER_STATE_PASSENGER)
    {
        return 1;
    }

    new const vehicleid = GetPlayerVehicleID(playerid);
    if (!Restore_IsVehicleIndexValid(vehicleid) ||
        s_RestoreManagedOwner[vehicleid] == INVALID_PLAYER_ID)
    {
        return 1;
    }

    new const ownerid = s_RestoreManagedOwner[vehicleid];

    if (ownerid != playerid ||
        s_RestoreManagedToken[vehicleid] !=
            s_RestoreVehicleToken[playerid] ||
        s_RestoreVehicle[playerid] != vehicleid)
    {
        RemovePlayerFromVehicle(playerid);
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Xe nay thuoc hop dong phuc che cua ky thuat vien khac.",
            4500
        );
        return 1;
    }

    if (s_RestoreContractStage[playerid] !=
        RESTORE_STAGE_TEST_DRIVE)
    {
        RemovePlayerFromVehicle(playerid);
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Xe chua hoan tat phuc che, ban chua the chay thu.",
            4000
        );
        return 1;
    }

    if (newstate == _:PLAYER_STATE_DRIVER)
    {
        SetVehicleParamsEx(
            vehicleid,
            VEHICLE_PARAMS_ON,
            VEHICLE_PARAMS_ON,
            -1,
            VEHICLE_PARAMS_OFF,
            -1,
            -1,
            VEHICLE_PARAMS_ON
        );
    }
    return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
    #pragma unused killerid

    if (!Restore_IsVehicleIndexValid(vehicleid) ||
        s_RestoreManagedOwner[vehicleid] == INVALID_PLAYER_ID)
    {
        return 1;
    }

    new const playerid = s_RestoreManagedOwner[vehicleid];
    new const vehicleToken = s_RestoreManagedToken[vehicleid];

    if (IsPlayerConnected(playerid) &&
        s_RestoreVehicle[playerid] == vehicleid &&
        s_RestoreVehicleToken[playerid] == vehicleToken)
    {
        if (Job_IsActive(playerid, JOB_CAR_RESTORATION))
        {
            Job_Stop(playerid, JOB_STOP_VEHICLE_LOST);
        }
        else
        {
            Restore_DestroyContractVehicle(playerid);
        }
    }
    else
    {
        s_RestoreManagedOwner[vehicleid] = INVALID_PLAYER_ID;
        s_RestoreManagedToken[vehicleid] = 0;
    }
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    if (Restore_HasContractVehicle(playerid) ||
        s_RestoreVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        Restore_DestroyContractVehicle(playerid);
    }
    return 1;
}

hook OnPlayerJobStopping(playerid, jobid, reason)
{
    if (jobid != JOB_CAR_RESTORATION)
    {
        return 1;
    }

    Restore_DestroyContractVehicle(playerid);

    if (reason == JOB_STOP_VEHICLE_LOST)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Xe hop dong da bi pha huy. Hop dong phuc che da huy.",
            5000
        );
    }
    else if (reason == JOB_STOP_DEATH)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Hop dong phuc che da huy vi ban bat tinh.",
            5000
        );
    }
    return 1;
}
