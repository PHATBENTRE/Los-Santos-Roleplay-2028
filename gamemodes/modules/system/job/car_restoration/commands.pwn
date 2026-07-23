//-----------------------------------------------------------------------------
// Car restoration job - commands
//-----------------------------------------------------------------------------

CMD:phucche(playerid, params[])
{
    #pragma unused params

    if (!pJobLoaded[playerid])
    {
        return Pizza_LoadCharacterJob(playerid);
    }

    if (Restore_IsEmployee(playerid))
    {
        return Restore_ShowEmployeeMenu(playerid);
    }

    return Restore_ShowApplication(playerid);
}

CMD:restorecar(playerid, params[])
{
    return cmd_phucche(playerid, params);
}
