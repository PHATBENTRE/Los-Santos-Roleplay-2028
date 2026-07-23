//-----------------------------------------------------------------------------
// Generic job system - shared data
//-----------------------------------------------------------------------------

#define MAX_JOB_TYPES                  (16)
#define MAX_JOB_NAME_LENGTH            (24)
#define MAX_JOB_HIRE_DATE_LENGTH       (20)
#define MAX_JOB_LEVEL                  (5)
#define JOB_MAX_SINGLE_PAYMENT         (5000)

enum _:E_JOB_TYPE
{
    JOB_NONE = 0,
    JOB_PIZZA,
    JOB_CAR_RESTORATION
};

enum _:E_JOB_STOP_REASON
{
    JOB_STOP_QUIT = 0,
    JOB_STOP_COMPLETE,
    JOB_STOP_DEATH,
    JOB_STOP_DISCONNECT,
    JOB_STOP_VEHICLE_LOST
};

new const g_JobLevelExperience[MAX_JOB_LEVEL + 1] =
{
    0,      // Unused.
    0,      // Level 1.
    150,    // Level 2.
    400,    // Level 3.
    800,    // Level 4.
    1400    // Level 5.
};

new
    bool:g_JobRegistered[MAX_JOB_TYPES],
    g_JobName[MAX_JOB_TYPES][MAX_JOB_NAME_LENGTH],

    s_PlayerActiveJob[MAX_PLAYERS],
    s_PlayerJobShiftEarnings[MAX_PLAYERS],
    s_PlayerJobCharacterID[MAX_PLAYERS],
    s_PlayerJobLoadToken[MAX_PLAYERS],
    bool:s_PlayerJobProgressLoaded[MAX_PLAYERS],
    bool:s_PlayerJobProgressLoading[MAX_PLAYERS],

    s_PlayerJobExperience[MAX_PLAYERS][MAX_JOB_TYPES],
    s_PlayerJobCompletedRuns[MAX_PLAYERS][MAX_JOB_TYPES],
    s_PlayerJobCompletedTasks[MAX_PLAYERS][MAX_JOB_TYPES],
    s_PlayerJobCurrentStreak[MAX_PLAYERS][MAX_JOB_TYPES],
    s_PlayerJobBestStreak[MAX_PLAYERS][MAX_JOB_TYPES],
    s_PlayerJobTotalEarnings[MAX_PLAYERS][MAX_JOB_TYPES];

new
    bool:s_PlayerJobEmployed[MAX_PLAYERS][MAX_JOB_TYPES],
    s_PlayerJobHiredAt[MAX_PLAYERS][MAX_JOB_TYPES][MAX_JOB_HIRE_DATE_LENGTH],
    s_PlayerJobDailySalary[MAX_PLAYERS][MAX_JOB_TYPES],
    s_PlayerJobDailyAllowance[MAX_PLAYERS][MAX_JOB_TYPES];

stock Job_ResetProgress(playerid)
{
    for (new jobid = 0; jobid < MAX_JOB_TYPES; jobid++)
    {
        s_PlayerJobExperience[playerid][jobid] = 0;
        s_PlayerJobCompletedRuns[playerid][jobid] = 0;
        s_PlayerJobCompletedTasks[playerid][jobid] = 0;
        s_PlayerJobCurrentStreak[playerid][jobid] = 0;
        s_PlayerJobBestStreak[playerid][jobid] = 0;
        s_PlayerJobTotalEarnings[playerid][jobid] = 0;
        s_PlayerJobEmployed[playerid][jobid] = false;
        s_PlayerJobHiredAt[playerid][jobid][0] = 0;
        s_PlayerJobDailySalary[playerid][jobid] = 0;
        s_PlayerJobDailyAllowance[playerid][jobid] = 0;
    }
    return 1;
}

stock Job_ResetPlayer(playerid)
{
    s_PlayerActiveJob[playerid] = JOB_NONE;
    s_PlayerJobShiftEarnings[playerid] = 0;
    s_PlayerJobCharacterID[playerid] = INVALID_CHARACTER_ID;
    s_PlayerJobLoadToken[playerid]++;
    s_PlayerJobProgressLoaded[playerid] = false;
    s_PlayerJobProgressLoading[playerid] = false;
    Job_ResetProgress(playerid);
    return 1;
}

stock bool:Job_IsValid(jobid)
{
    return jobid > JOB_NONE &&
        jobid < MAX_JOB_TYPES &&
        g_JobRegistered[jobid];
}

stock Job_GetLevel(playerid, jobid)
{
    if (!Job_IsValid(jobid))
    {
        return 0;
    }

    new level = 1;

    for (new nextLevel = 2; nextLevel <= MAX_JOB_LEVEL; nextLevel++)
    {
        if (s_PlayerJobExperience[playerid][jobid] <
            g_JobLevelExperience[nextLevel])
        {
            break;
        }

        level = nextLevel;
    }

    return level;
}

stock Job_GetNextLevelExperience(level)
{
    if (level < 1 || level >= MAX_JOB_LEVEL)
    {
        return 0;
    }

    return g_JobLevelExperience[level + 1];
}

stock Job_GetName(jobid, destination[], size)
{
    if (!Job_IsValid(jobid))
    {
        format(destination, size, "Khong co");
        return 0;
    }

    format(destination, size, "%s", g_JobName[jobid]);
    return 1;
}

stock Job_GetActive(playerid)
{
    return s_PlayerActiveJob[playerid];
}

stock bool:Job_IsActive(playerid, jobid)
{
    return s_PlayerActiveJob[playerid] == jobid;
}

stock bool:Job_IsProgressReady(playerid)
{
    return s_PlayerJobProgressLoaded[playerid] &&
        s_PlayerJobCharacterID[playerid] == GetPlayerCharacterID(playerid);
}

stock bool:Job_IsEmployed(playerid, jobid)
{
    return Job_IsValid(jobid) &&
        s_PlayerJobEmployed[playerid][jobid];
}

stock Job_GetDailySalary(playerid, jobid)
{
    if (!Job_IsValid(jobid))
    {
        return 0;
    }
    return s_PlayerJobDailySalary[playerid][jobid];
}

stock Job_GetDailyAllowance(playerid, jobid)
{
    if (!Job_IsValid(jobid))
    {
        return 0;
    }
    return s_PlayerJobDailyAllowance[playerid][jobid];
}

stock Job_GetHiredAt(playerid, jobid, destination[], size)
{
    if (!Job_IsEmployed(playerid, jobid) ||
        !s_PlayerJobHiredAt[playerid][jobid][0])
    {
        format(destination, size, "Chua co");
        return 0;
    }

    format(
        destination,
        size,
        "%s",
        s_PlayerJobHiredAt[playerid][jobid]
    );
    return 1;
}
